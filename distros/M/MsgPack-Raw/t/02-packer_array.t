#!perl

use Test::More;
use MsgPack::Raw;

my $packer = MsgPack::Raw::Packer->new;
isa_ok $packer, 'MsgPack::Raw::Packer';

sub true { MsgPack::Raw::Bool::true() }
sub false { MsgPack::Raw::Bool::false() }


sub packit
{
    local $_ = unpack ("H*", $packer->pack ($_[0]));
    s/(..)/$1 /g;
    s/ $//;
    $_;
}

my @data =
(
    [], '90',
    [+[]], '91 90',
    [[], undef], '92 90 c0',
    [undef, false, true], '93 c0 c2 c3',
    ["", "a", "bc", "def"], '94 c4 00 c4 01 61 c4 02 62 63 c4 03 64 65 66',
    [[], [[undef]]], '92 90 91 91 c0',
    [undef, false, true], '93 c0 c2 c3',
    [[0, 64, 127], [-32, -16, -1]], '92 93 00 40 7f 93 e0 f0 ff',
    [0, -128, -1, 0, -32768, -1, 0, -2147483648, -1], '99 00 d0 80 ff 00 d1 80 00 ff 00 d2 80 00 00 00 ff',
    [(undef) x 0x0100], 'dc 01 00' . (' c0' x 0x0100),
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
