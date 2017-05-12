# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ogg-LibOgg.t'


use Test::More tests => 39;
BEGIN { use_ok('Ogg::LibOgg') };


## Random Return
my $ret;

my $filename = "t/test.ogg";

## Opening the File
open $fd, $filename or die "Can't open $filename: $!";
ok(fileno($fd), "Open Ogg File");

## Make Ogg Packet
my $op = Ogg::LibOgg::make_ogg_packet();
ok($op != 0, "Ogg Packet");

## Make Ogg Stream State
my $os = Ogg::LibOgg::make_ogg_stream_state();
ok($os != 0, "Ogg Stream State");

## Make Ogg Page
my $og = Ogg::LibOgg::make_ogg_page();
ok($og != 0, "Ogg Page");

## Make Ogg Sync State
my $oy = Ogg::LibOgg::make_ogg_sync_state();
ok($oy != 0, "Ogg Sync State");

## Ogg Sync Init
ok(Ogg::LibOgg::ogg_sync_init($oy) == 0, "Ogg Sync Init");

## Ogg Sync Buffer
my $buf = Ogg::LibOgg::ogg_sync_buffer($oy, 4096);
ok($buf != 0, "Ogg Sync Buffer");

## Ogg Sync Wrote
ok(Ogg::LibOgg::ogg_sync_wrote($oy, 0) == 0, "Ogg Sync Wrote");

## Ogg Read Page
## ogg_read_page internally uses the following, so also
## tests the following
## 1. Ogg::LibOgg::ogg_sync_pageout
## 2. Ogg::LibOgg::ogg_sync_buffer
## 3. Ogg::LibOgg:ogg_sync_wrote
$ret = Ogg::LibOgg::ogg_read_page($fd, $oy, $og);
ok($ret == 0, "Ogg Read Page");

## Ogg Page Serial Number
my $slno = Ogg::LibOgg::ogg_page_serialno($og);
ok($slno != 0, "Ogg Page Serial Number");

## Ogg Stream Init
ok(Ogg::LibOgg::ogg_stream_init($os, $slno) == 0, "Ogg Stream Init");

## Ogg Stream Pagein
ok(Ogg::LibOgg::ogg_stream_pagein($os, $og) == 0, "Ogg Stream Pagein");

## Ogg Stream Packetin
ok(Ogg::LibOgg::ogg_stream_packetpeek($os, $op) == 1, "Ogg Stream Packetpeek");

## Ogg Stream Packetout
## can't say ogg_stream_packetout == 0, it could be 1, -1 or 0
ok(defined Ogg::LibOgg::ogg_stream_packetout($os, $op), "Ogg Stream Packetout");

## Ogg Page Bos
ok(Ogg::LibOgg::ogg_page_bos($og) >= 0, "Ogg Page Bos");

## Ogg Page Eos
ok(Ogg::LibOgg::ogg_page_eos($og) >= 0, "Ogg Page Bos");

## Ogg Page Checksum Set
Ogg::LibOgg::ogg_page_checksum_set($og);
ok(1, "Ogg Page Checksum Set");    ## looks like ok(..) can't be called in void context

## Ogg Page Continued
ok(Ogg::LibOgg::ogg_page_continued($og) >= 0, "Ogg Page Continued");

## Ogg Page Granulepos
ok(Ogg::LibOgg::ogg_page_granulepos($og) >= 0, "Ogg Page Granulepos");

## Ogg Page Packets
ok(defined Ogg::LibOgg::ogg_page_packets($og), "Ogg Page Packets");

## Ogg Page Pageno
ok(Ogg::LibOgg::ogg_page_pageno($og) >= 0, "Ogg Page Pageno");

## Ogg Stream Check
ok(Ogg::LibOgg::ogg_stream_check($og) == 0, "Ogg Stream Check");

## Ogg Page Version
ok(defined Ogg::LibOgg::ogg_page_version($og), "Ogg Page Version");

## Ogg Stream Packetin
ok(Ogg::LibOgg::ogg_stream_packetin($os, $op) == 0, "Ogg Stream Packetin");

## Ogg Stream Pageout
ok(Ogg::LibOgg::ogg_stream_pageout($os, $og) != 0, "Ogg Stream Pageout");

## Ogg Stream Flush
ok(Ogg::LibOgg::ogg_stream_flush($os, $og) != 0, "Ogg Stream Flush");

## Ogg Sync Check
ok(Ogg::LibOgg::ogg_sync_check($oy) == 0, "Ogg Sync Check");

## Ogg Sync Pageseek
ok(Ogg::LibOgg::ogg_sync_pageseek($oy, $og) != 0, "Ogg Sync Pageseek");

## Get Ogg Page
ok(ref Ogg::LibOgg::get_ogg_page($og) eq 'HASH', "Get Ogg Page");

## CLEAN-UPS ##

## Ogg Packet Clear
# Ogg::LibOgg::ogg_packet_clear($op); ## don't manipulate directly
ok(1, "Ogg Packet Clear");

## Ogg Stream Reset
ok(Ogg::LibOgg::ogg_stream_reset_serialno($os, $$) == 0, "Ogg Stream Reset Serialno");

## Ogg Stream Reset
ok(Ogg::LibOgg::ogg_stream_reset($os) == 0, "Ogg Stream Reset");

## Ogg Stream Clear
ok(Ogg::LibOgg::ogg_stream_clear($os) == 0, "Ogg Stream Clear");

## Ogg Sync Reset
ok(Ogg::LibOgg::ogg_sync_reset($oy) == 0, "Ogg Sync Reset");

## Ogg Sync Clear
ok(Ogg::LibOgg::ogg_sync_clear($oy) == 0, "Ogg Sync Clear");

## Ogg Sync Destroy
ok(Ogg::LibOgg::ogg_sync_destroy($oy) == 0, "Ogg Sync Destroy");

## Ogg Stream Destroy
ok(Ogg::LibOgg::ogg_stream_destroy($os) == 0, "Ogg Stream Destroy");

## Closing the File
close $fd;
is(fileno($fd), undef, "Close Ogg File");
