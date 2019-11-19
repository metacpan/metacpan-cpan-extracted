#!perl

use Test::More;
use MsgPack::Raw;

my $obj1 = MsgPack::Raw::Ext->new (1, 'data');
my $obj2 = MsgPack::Raw::Ext->new (1, 'data2');
my $obj3 = MsgPack::Raw::Ext->new (2, 'data');
my $obj4 = MsgPack::Raw::Ext->new (1, 'data');

isa_ok $obj1, 'MsgPack::Raw::Ext';
isa_ok $obj2, 'MsgPack::Raw::Ext';
isa_ok $obj3, 'MsgPack::Raw::Ext';

ok $obj1 != $obj2;
ok $obj1 != $obj3;
ok $obj1 == $obj4;
ok $obj2 != $obj3;
ok $obj2 != $obj4;
ok $obj3 != $obj4;

done_testing;
