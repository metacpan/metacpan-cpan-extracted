use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 3;
use Test::Mojo;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'Directory::Stylish', root => $dir, enable_json => 1;

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    my $entries;
    while ( defined( my $ent = $dh->read ) ) {
        next if -d $ent or $ent eq '.' or $ent eq '..';
        $entries++;
    }
    $t->get_ok('/?format=json')->status_is(200)->json_has('/current')->json_has('/files');
}
