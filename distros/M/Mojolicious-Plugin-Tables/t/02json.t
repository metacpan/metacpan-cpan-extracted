use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $testdir;
BEGIN {
    use File::Basename 'dirname';
    $testdir = dirname(__FILE__);
    $ENV{EXAMPLEDB} = "$testdir/example.db";
}
use lib "$testdir/blah/lib";

my $t = Test::Mojo->new('Blah');

$t->get_ok('/'                         => 'App starts');

$t->get_ok('/tables/artist/1/cds.json' => 'Artist child ("CDs") json query succeeds');

#note "GOT",  explain $t->tx->res->json;

$t->json_has('/1/label'                => 'json response has "label" field');
$t->json_is ('/1/label', '[Cd] 2'      => 'label is "[Cd 2]"');

done_testing();
