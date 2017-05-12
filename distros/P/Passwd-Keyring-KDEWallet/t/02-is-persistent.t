#!perl 

use strict;
use warnings;
use Test::More;
use Passwd::Keyring::KDEWallet;

if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 2;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}

SKIP: {
    my $ring;
    eval {
        $ring = Passwd::Keyring::KDEWallet->new;
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 2;
        } else {
            die $@;
        }
    }

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet',   'new() works' );

    ok( $ring->is_persistent eq 1, "is_persistent knows we are persistent");
}

