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
    MsgPack::Raw::Ext->new (85, ""), 'c7 00 55',
    MsgPack::Raw::Ext->new (85, "a"), 'd4 55 61',
    MsgPack::Raw::Ext->new (85, "aa"), 'd5 55 61 61',
    MsgPack::Raw::Ext->new (85, "aaaa"), 'd6 55 61 61 61 61',
    MsgPack::Raw::Ext->new (85, "aaaaaaaa"), 'd7 55 61 61 61 61 61 61 61 61',
    MsgPack::Raw::Ext->new (85, "aaaaaaaaaaaaaaaa"), 'd8 55 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
    MsgPack::Raw::Ext->new (85, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"), 'c7 1f 55 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
    MsgPack::Raw::Ext->new (85, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"), 'c7 20 55 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
    MsgPack::Raw::Ext->new (85, "a" x 255), 'c7 ff 55'.' 61' x 255,
    MsgPack::Raw::Ext->new (85, "a" x 256), 'c8 01 00 55'.' 61' x 256,
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
