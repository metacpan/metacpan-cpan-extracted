use strict;
use warnings;
use Test::More 0.98;
use Test::Mojo;
use File::Temp ();
use Mojo::File qw(path);

my $outer = path( File::Temp::tempdir( CLEANUP => 1 ) );
my $repo  = $outer->child('repo')->make_path;
$outer->child('secret.txt')->spurt('top secret');
$repo->child('hello.txt')->spurt('hello');

$ENV{DARKPAN_DIRECTORY} = $repo->to_string;
delete $ENV{$_} for grep { /^DARKPAN_(AUTH|CONFIG|PATH|COMPRESS)/ } keys %ENV;

my $t = Test::Mojo->new('Mojo::Darkpan');

subtest 'delivery' => sub {
    $t->get_ok('/darkpan/hello.txt')->status_is(200)->content_is('hello');
    $t->get_ok('/darkpan/')->status_is(200)->content_like(qr/hello\.txt/);
};

subtest 'delivery does not escape the repository' => sub {
    for my $p (
        '/darkpan/..%2fsecret.txt',
        '/darkpan/%2e%2e%2fsecret.txt',
        '/darkpan/..%2f..%2f..%2f..%2f..%2f..%2fetc/passwd',
      )
    {
        $t->get_ok($p)->status_is(404)->content_unlike(qr/top secret|root:/);
    }
};

subtest 'list on an empty repository' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $t->get_ok('/list')->status_is(200)->json_is( {} );
    is_deeply \@warnings, [], 'no warnings';
};

subtest 'reindex requires authorization' => sub {
    my $started = 0;
    no warnings qw(redefine once);
    local *Mojo::Darkpan::Util::createIndex = sub { $started++ };

    $t->get_ok('/reindex')->status_is(200);
    is $started, 1, 'reindex runs when no auth is configured';

    $started = 0;
    local $ENV{DARKPAN_AUTH_REALM} = 'test';
    local $ENV{DARKPAN_AUTH_host}  = 'ldaps://invalid.example';
    $t->get_ok('/reindex')->status_is(401);
    is $started, 0, 'reindex does not run for an unauthenticated request';
};

subtest 'config honours false values from the config file' => sub {
    my $cfg = $outer->child('config.json');
    $cfg->spurt('{"compress_index": false}');
    local $ENV{DARKPAN_CONFIG_FILE} = $cfg->to_string;
    require Mojo::Darkpan::Config;
    ok( Mojo::Darkpan::Config->new->no_compress, 'compress_index false disables compression' );
};

done_testing;
