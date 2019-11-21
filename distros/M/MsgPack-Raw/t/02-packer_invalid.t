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

# not allowed
ok (!eval {$packer->pack (MsgPack::Raw::Ext->new (undef, ""))});
ok (!eval {$packer->pack (MsgPack::Raw::Ext->new (1, undef))});
ok (!eval {$packer->pack (MsgPack::Raw::Ext->new (-1, ""))});
ok (!eval {$packer->pack (MsgPack::Raw::Ext->new (256, ""))});
ok (!eval {$packer->pack (MsgPack::Raw::Packer->new)});
ok (!eval {$packer->pack (sub {})});

done_testing;
