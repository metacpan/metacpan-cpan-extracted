#!perl

use Test::More;
use MsgPack::Raw;

my $unpacker = MsgPack::Raw::Unpacker->new;

$unpacker->feed ("\xd4\x55\x61"); # ext => 'a'
$unpacker->feed ("\xc7\x00\x55"); # ext => ''

ok $unpacker->next == MsgPack::Raw::Ext->new (85, "a");
ok $unpacker->next == MsgPack::Raw::Ext->new (85, "");
ok !$unpacker->next, 'everything consumed';

done_testing();

