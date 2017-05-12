# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/PSGRAPH.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# change tests 'no_plan' to tests => number for tests after development
#use Test::More tests => 1;
#use Test::More 'no_plan';
use Test::More tests => 21;
BEGIN { use_ok('PSGRAPH') }; #test 1

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $psgraph = PSGRAPH->new();
my @lc;
my @da;

#########################
$psgraph->setLabelandColor('samplelabelandcolor');
my $labelandcolor = $psgraph->getLabelandColor;
is($labelandcolor, 'samplelabelandcolor', 'labelandcolor should be samplelabelandcolor'); #test 2

#########################
open(LC, ">samplelabelandcolor");
print LC ".23	.65	1	0	A\n";
close LC;
open(LC, "samplelabelandcolor");
while(<LC>){
	@lc=split("\t");
}
close LC;
is(@lc, 5, 'lc should be a tab delimited file with five fields'); #test 3

#########################
$psgraph->setData('piedata');
my $data = $psgraph->getData;
is($data, 'piedata', 'data should be piedata'); #test 4

#########################
open(DATA, ">piedata");
print DATA "23	99	87	20	131	smith\n";
close DATA;
open(DATA, "piedata");
while(<DATA>){
    @da=split("\t");
}
close DATA;
is(@da, 6, 'data should be a tab delimited file with six fields'); #test 5

#########################
my $piedegrees = $da[0] + $da[1] + $da[2] + $da[3] + $da[4];
is($piedegrees, 360, 'There should be 360 degrees in a pie'); #test 6

#########################
$psgraph->setGraphic('2Dpie');
my $graphic = $psgraph->getGraphic;
is($graphic, '2Dpie', 'graphic should be 2Dpie'); #test 7

#########################
$psgraph->setSubtype(3);
my $subtype = $psgraph->getSubtype;
is($subtype, 3, 'subtype should be 3'); #test 8

#########################
$psgraph->setHscale(.63);
my $hscale = $psgraph->getHscale;
is($hscale, .63, 'hscale should be .63'); #test 9

#########################
$psgraph->setVscale(.56);
my $vscale = $psgraph->getVscale;
is($vscale, .56, 'vscale should be .56'); #test 10

#########################
my $ps = $psgraph->setPS('pie');
is($ps, 'ERROR: Unsupported graphic.', 'ps should be ERROR...'); #test 11

#########################
$psgraph->setGraphic('2Dblob');
my $phonygraphic = $psgraph->getGraphic;
my $wg = $psgraph->writeGraphic;
is($wg, 'Cannot write undefined graphic!', 'wg should be Cannot write undefined graphic!'); #test 12
is($phonygraphic, '2Dblob', 'should be 2Dblob');	#test 13

#########################
$psgraph->setColumnwidth(36);
my $columnwidth = $psgraph->getColumnwidth;
is($columnwidth, 36, 'columnwidth should be 36'); #test 14

#########################
$psgraph->setFormat('d2');
my $format = $psgraph->getFormat;
is($format, 'd2', 'format should be d2'); #test 15

#########################
$psgraph->setHeadertype(17);
my $headertype = $psgraph->getHeadertype;
is($headertype, 17, 'headertype should be 17'); #test 16

#########################
$psgraph->setHeadercolor('.2 .130 .22 0');
my $headercolor = $psgraph->getHeadercolor;
is($headercolor, '.2 .130 .22 0', 'headercolor should be .2 .130 .22 0'); #test 17

#########################
$psgraph->setAxistype(18);
my $axistype = $psgraph->getAxistype;
is($axistype, 18, 'axistype should be 18'); #test 18

#########################
$psgraph->setValuetype(72);
my $valuetype = $psgraph->getValuetype;
is($valuetype, 72, 'valuetype should be 72'); #test 19

#########################
$psgraph->setValuecolor(1);
my $valuecolor = $psgraph->getValuecolor;
is($valuecolor, 1, 'valuecolor should be 1'); #test 20

#########################
$psgraph->setBackgroundcolor('0 1 0 0');
my $backgroundcolor = $psgraph->getBackgroundcolor;
is($backgroundcolor, '0 1 0 0', 'backgroundcolor should be 0 1 0 0'); #test 21


