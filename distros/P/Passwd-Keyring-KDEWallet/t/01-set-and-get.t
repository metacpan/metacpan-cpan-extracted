#!perl 

use strict;
use warnings;
use Test::More;

if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 9;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}

use Passwd::Keyring::KDEWallet;

SKIP: {

    my $ring;
    eval {
        $ring = Passwd::Keyring::KDEWallet->new;
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 9;
        } else {
            die $@;
        }
    }

    ok( defined($ring), "new() constructed something");
    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet', 'new() constructed KDEWallet' );

    my $USER = 'John';
    my $PASSWORD = 'verysecret';
    my $REALM = 'some simple realm';

    $ring->set_password($USER, $PASSWORD, $REALM);

    ok( 1, "set_password works" );

    is( $ring->get_password($USER, $REALM), $PASSWORD, "get recovers");

    is( $ring->clear_password($USER, $REALM), 1, "clear_password removed one password" );

    is( $ring->get_password($USER, $REALM), undef, "no password after clear");

    is( $ring->clear_password($USER, $REALM), 0, "clear_password again has nothing to clear" );

    is( $ring->clear_password("Non user", $REALM), 0, "clear_password for unknown user has nothing to clear" );
    is( $ring->clear_password("$USER", 'non realm'), 0, "clear_password for unknown realm has nothing to clear" );

}
