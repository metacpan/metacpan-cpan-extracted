#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
isa_ok $packer, 'MsgPack::Raw::Packer';

sub packit
{
    local $_ = unpack ("H*", $packer->pack ($_[0]));
    s/(..)/$1 /g;
    s/ $//;
    $_;
}

my @data =
(
    -32,   'e0',
    -33,   'd0 df',
    -128,  'd0 80',
    -129,  'd1 ff 7f',
    -32768, 'd1 80 00',
    -32769, 'd2 ff ff 7f ff',
    -2147483648, 'd2 80 00 00 00',
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
