#!perl -w

use Test::More tests => 20; 
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

note("Testing some DS editing ...");
ok($rrd->rename_DS("el1","new1"),"rename_DS()");
ok($rrd->set_DS_heartbeat("el2",1200), "set_DS_heartbeat()");
ok($rrd->set_DS_type("el2","ABSOLUTE"),"set_DS_type()");
ok($rrd->set_DS_min("el2",0),"set_DS_min()");
ok($rrd->set_DS_max("el2",1),"set_DS_max()");
ok($rrd->add_DS("DS:added:GAUGE:600:U:U"),"add_DS()");
ok($rrd->delete_DS("el3"),"delete_DS()");
#open $fd, ">t/test.rrd.ds_editing.dump"; print $fd $rrd->dump("-t -d=5"); close $fd;
note("Check the result is what we expect ...");
open $fd, "<$scriptdir/test.rrd.ds_editing.dump"; @file=<$fd>; ;close $fd;
my $dump=$rrd->dump("-t -d=5"); #$dump=~ s/UTC/GMT/g;
is (lc($dump), lc(join("",@file)), "DS editing");
$rrd->close();

note("Testing some RRA editing ...");
$rrd->open("t/test.rrd");
ok($rrd->set_RRA_xff(1,0), "set_RRA_xff()");
ok($rrd->set_RRA_el(1,"el1",2,100),"set_RRA_el()");
ok($rrd->resize_RRA(1,20), "resize_RRA()");
ok($rrd->add_RRA("RRA:AVERAGE:0.5:3:10"),"add_RRA()");
ok($rrd->delete_RRA(0),"delete_RRA()");
#open $fd, ">t/test.rrd.rra_editing.dump"; print $fd $rrd->dump("-t -d=5"); close $fd;
note("Check the result is what we expect ...");
open $fd, "<$scriptdir/test.rrd.rra_editing.dump"; @file=<$fd>; ;close $fd;
$dump=$rrd->dump("-t -d=5"); #$dump=~ s/UTC/GMT/g;
is (lc($dump), lc(join("",@file)), "RRA editing");
$rrd->close();

note("Checking update using partial template ...");
$rrd->open("t/test.rrd");
my $fileDB='';
$rrd->{file_name}=\$fileDB;
ok($rrd->save(),"save()"); # save RRD to string in memory (no need for temp file)
my $j=$rrd->last()+300; ok($rrd->update("-t el1:el2:el4 $j:67:1.0:2"));
my @vals=$rrd->lastupdate(); 
is (lc(join(" ",@vals)), lc("67 1.0 u 2"), "Partial template update");

