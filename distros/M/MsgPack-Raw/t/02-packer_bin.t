#!perl

use Test::More;
use MsgPack::Raw;
use Encode;

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
	"",    'c4 00',
    "a",   'c4 01 61',
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 'c4 1f 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 'c4 20 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61',
);

for (my $i = 0; $i < scalar (@data); $i += 2)
{
	is packit ($data[$i]), $data[$i+1], "dump ".$data[$i+1];
}

done_testing;
