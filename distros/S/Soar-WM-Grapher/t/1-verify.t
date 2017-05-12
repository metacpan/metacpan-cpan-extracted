#test that the module is loaded properly

use strict;
use Test::More 0.88;
plan tests => 7;
use Soar::WM::Grapher qw(wm_graph);
use GraphViz;
use Test::Warn;
use Data::Section::Simple qw(get_data_section);

my $allData = get_data_section;
my $wmText = $allData->{'small text'};
my $wm = Soar::WM->new(text => $wmText);
warning_like { wm_graph() } {carped => qr/Usage:/}, 'number of args checked';
warning_like { wm_graph($wm) } {carped => qr/Usage:/}, 'number of args checked';
warning_like { wm_graph($wm, 'S1') } {carped => qr/Usage:/}, 'number of args checked';

my $g = wm_graph($wm, 's1', 1);
isa_ok($g, 'GraphViz');

warning_is {$g = wm_graph($wm, 's1', 1);} undef, "Graph args processed without error";
isa_ok($g, 'GraphViz');

TODO:{
	local $TODO = "Don't know how to test that a GraphViz object was correctly created";
	ok(0, 'Graph structure is correct');
	#test correct graphing here
}

__DATA__
@@ small text
(S1 ^foo bar ^foo buzz ^baz boo ^link S2 ^link S3)
(S2 ^faz far 
	^boo baz
	^fuzz buzz)
(S3 ^junk foo)