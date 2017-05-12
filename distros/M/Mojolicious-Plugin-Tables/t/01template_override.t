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

$t->get_ok('/tables'               => 'tables page exists');

$t->get_ok('/tables/artist/1/view' => 'Row view page appears');
$t->text_is('div#tablesbody span#name' => 'Michael Jackson' => 'normal body good');

$t->get_ok('/tables/track/4/view' => 'Row view page appears for customised template');
$t->text_is('h1#custom-track-data' => 'Leave Me Alone' => 'normal body good');

#note "GOT",  explain $t->tx->res->dom->at('div#tablesbody');
#
done_testing();
