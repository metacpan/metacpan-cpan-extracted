#!perl -T

use Test::More tests => 6;
use Parse::Tektronix::ISF;

$isf = 't/test.isf';
$ret = Parse::Tektronix::ISF::Read('NOTEXISTFILE');
ok(!$ret, "check return value for non-existent file");
$ret = Parse::Tektronix::ISF::Read($isf);
ok($ret, "check return value for a test file");
is($ret->{NR_PT}, 10000, 'check number of points read out from header');
is(@{$ret->{DATA}}, 10000, 'check number of points read out from data block');
is($ret->{DATA}[6449][0], -1.102e-07, 'check x of 6423rd point');
is($ret->{DATA}[6449][1], 0.0113625, 'check y of 6423rd point');


