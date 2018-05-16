#!/usr/bin/perl

use Test::More tests => 19;

use lib '../lib', 'lib';

use_ok('SMB::Packer');
use_ok('SMB::Parser');
use_ok('SMB::v2::Command');

use if (1 << 32 == 1), 'bigint';  # support native uint64 on 32-bit platforms

my $big = (456 << 32) + 456;

my $packer = SMB::Packer->new;

$packer->uint64(123);
is($packer->size, 8,              "size after uint64");
$packer->mark('second-64bit-word');
$packer->uint64(456);
is($packer->offset, 16,           "offset after uint64");
# pack 7 SMB2 style fids
$packer->uint32(0xffffffff) for 0 .. 6;
$packer->uint32(0xfffffffe) for 0 .. 1;
$packer->uint32(0xffffffff) for 0 .. 2;
$packer->uint32(0) for 0 .. 2;
$packer->uint32(1) for 0 .. 1;
$packer->uint32(0) for 0 .. 6;
$packer->fid2([$big, 2]);
is($packer->size, 128,            "size after packing fids");

$packer->jump('second-64bit-word');
is($packer->offset, 8,            "offset after jump");
$packer->skip(4)->uint32(456);
is($packer->offset, 16,           "offset after replace");
is($packer->size, 128,            "size after all");

my $parser = SMB::Parser->new($packer->data);

is($parser->uint64, 123,          "first uint64");
is($parser->uint64, $big,         "second uint64");

$command = SMB::v2::Command;

my $fid = $parser->fid2;
ok($command->is_fid_unset($fid),  "1-st fid unset");
$fid = $parser->fid2;
ok(!$command->is_fid_unset($fid), "2-nd fid not unset");
$fid = $parser->fid2;
ok(!$command->is_fid_unset($fid), "3-rd fid not unset");
$fid = $parser->fid2;
ok(!$command->is_fid_null($fid),  "4-th fid not null");
$fid = $parser->fid2;
ok(!$command->is_fid_null($fid),  "5-th fid not null");
$fid = $parser->fid2;
ok($command->is_fid_null($fid),   "6-th fid null");
$fid = $parser->fid2;
is($fid->[0], $big,               "7-th fid, 1-st half");
is($fid->[1], 2,                  "7-th fid, 2-nd half");

