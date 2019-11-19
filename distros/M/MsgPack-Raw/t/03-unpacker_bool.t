#!perl

use Test::More;
use MsgPack::Raw;

my $obj;
my $unpacker = MsgPack::Raw::Unpacker->new;
my $packer = MsgPack::Raw::Packer->new;

$unpacker->feed ($packer->pack (MsgPack::Raw::Bool::true()));
$obj = $unpacker->next;
isa_ok $obj, 'MsgPack::Raw::Bool';
is $obj, MsgPack::Raw::Bool::true();
is 0+$obj, 1;
is $obj, "true";

$unpacker->feed ($packer->pack (MsgPack::Raw::Bool::false()));
$obj = $unpacker->next;
isa_ok $obj, 'MsgPack::Raw::Bool';
is $obj, MsgPack::Raw::Bool::false();
is 0+$obj, 0;
is $obj, "false";

done_testing();

