#!perl -w

use Test::More tests => 19;
use File::Spec;
use File::Basename qw(dirname);
my $scriptdir=File::Spec->rel2abs(dirname(__FILE__));

BEGIN {
  use_ok('RRD::Editor') or BAIL_OUT("cannot load the module");
}

note("Testing RRD::Editor $RRD::Editor::VERSION, Perl $], $^X");

my $rrd = new_ok ( "RRD::Editor");

note("Opening RRD file ...");
ok($rrd->open("$scriptdir/test.rrd"), 'open()');
note("Opened.");

note("Checking rrd->info() output ...");
open my $fd, "<$scriptdir/test.rrd.info"; my @file=<$fd>; my $file=join("",@file);
is(lc($rrd->info("-d=5 -n")), lc($file), 'info()');

note("Checking rrd->dump() output ...");
open $fd, "<$scriptdir/test.rrd.dump"; @file=<$fd>;  $file=join("",@file);
my $dump=$rrd->dump("-t -d=5"); #$dump=~ s/UTC/GMT/g;
is(lc($dump), lc($file), 'dump()');

note("Checking rrd->fetch() output ...");
open $fd, "<$scriptdir/test.rrd.fetch"; @file=<$fd>;  $file=join("",@file);
is(lc($rrd->fetch("AVERAGE -s=920804399 -d=5")), lc($file), "fetch()"); 

note("Checking rrd->last() output ...");
ok($rrd->last() == 920806800, 'last():'.$rrd->last());

note("Checking other output ...");
ok($rrd->minstep() == 300, 'minstep():'.$rrd->minstep() );

is(join(" ",$rrd->lastupdate()), "67 1.0 789 2", 'lastupdate():'.join(" ",$rrd->lastupdate()));

is(join(" ",$rrd->DS_names()), "el1 el2 el3 el4", "DS_names():".join(" ",$rrd->DS_names()));

cmp_ok($rrd->DS_heartbeat("el1"), '==', 600, "DS_heartbeat():".$rrd->DS_heartbeat("el1")); 

is($rrd->DS_type("el1"), "COUNTER", "DS_type():".$rrd->DS_type("el1"));

my $x=$rrd->DS_min("el1");ok(RRD::Editor::_isNan($x), "DS_min():$x");

$x=$rrd->DS_max("el1"); ok(RRD::Editor::_isNan($x), "DS_max():$x");

cmp_ok($rrd->RRA_numrows(0),'==', 5, "RRA_numrows():".$rrd->RRA_numrows(0));

cmp_ok($rrd->RRA_xff(0),'==', 0.5, "RRA_xff():".$rrd->RRA_xff(0));

cmp_ok($rrd->RRA_step(0), '==', 300, "RRA_step():".$rrd->RRA_step(0));

(my $t, my $el) = $rrd->RRA_el(0,"el1",2);
cmp_ok($t, '==', 920806200, "RRA_el():".join(" ",$rrd->RRA_el(0,"el1",2)));
is(sprintf("%0.2f",$el), "0.24","RRA_el():".join(" ",$rrd->RRA_el(0,"el1",2)));
note("done");



