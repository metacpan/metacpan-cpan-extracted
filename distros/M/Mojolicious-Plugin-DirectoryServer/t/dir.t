use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;
use Encode ();
use version;

my $dir = dirname(__FILE__);
plugin 'DirectoryServer', root => $dir, json => 1;

use Test::More tests => 2;
use Test::Mojo;

my $t = Test::Mojo->new;

subtest 'entries' => sub {
    $t->get_ok('/')->status_is(200);

    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        $ent = Encode::decode_utf8($ent);
        $t->content_like(qr/$ent/);
    }
};

subtest 'json' => sub {
    my $res = $t->get_ok('/?_format=json')->status_is(200);
    if ( version->parse($Mojolicious::VERSION)->numify >= version->parse('6.09')->numify ) {
        $res->content_type_is('application/json;charset=UTF-8');
    } else {
        $res->content_type_is('application/json');
    }
};
