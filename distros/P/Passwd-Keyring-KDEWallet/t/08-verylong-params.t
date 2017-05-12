#!perl

use strict;
use warnings;
use Test::More;
use Passwd::Keyring::KDEWallet;


if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 4;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}


my $APP = "Passwd::KDEWallet::Keyring unit test 08 ";
$APP .= "X" x (256 - length($APP));
my $GROUP = "Passwd::KDEWallet::Keyring unit tests ";
$GROUP .= "X" x (256 - length($GROUP));

my $USER = "A" x 256;
my $PWD =  "B" x 256;
my $REALM = 'C' x 256;

SKIP: {
    my $ring; 

    eval {
        $ring = Passwd::Keyring::KDEWallet->new(
            app=>$APP, group=>$GROUP);
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 4;
        } else {
            die $@;
        }
    }

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet',   'new() works with long params' );

    $ring->set_password($USER, $PWD, $REALM);

    ok( 1, "set_password with long params works" );

    ok( $ring->get_password($USER, $REALM) eq $PWD, "get_password with long params works");

    ok( $ring->clear_password($USER, $REALM) eq 1, "clear_password with long params works");

}
