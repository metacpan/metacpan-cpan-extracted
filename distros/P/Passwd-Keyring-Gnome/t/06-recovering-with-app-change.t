#!perl -T

use strict;
use warnings;
use Test::More;

if($ENV{GNOME_KEYRING_CONTROL}) {
    plan tests => 16;
} else {
    plan skip_all => "Keyring not available (not running under Gnome?), skipping tests";
}


use Passwd::Keyring::Gnome;

my $USER = "Herakliusz";
my $REALM = "test realm";
my $PWD = "arcytajne haslo";
my $PWD2 = "inny sekret";

my $APP1 = "Passwd::Keyring::Unit tests (1)";
my $APP2 = "Passwd::Keyring::Unit tests (2)";
my $GROUP1 = "Passwd::Keyring::Unit tests - group 1";
my $GROUP2 = "Passwd::Keyring::Unit tests - group 2";
my $GROUP3 = "Passwd::Keyring::Unit tests - group 3";

my @cleanups;

{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP1, group=>$GROUP1);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome',   'new() works' );

    ok( ! defined($ring->get_password($USER, $REALM)), "initially unset");

    $ring->set_password($USER, $PWD, $REALM);
    ok(1, "set password");

    ok( $ring->get_password($USER, $REALM) eq $PWD, "normal get works");

    push @cleanups, sub {
        ok( $ring->clear_password($USER, $REALM) eq 1, "clearing");
    };
}


# Another object with the same app and group

{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP1, group=>$GROUP1);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome', 'second new() works' );

    ok( $ring->get_password($USER, $REALM) eq $PWD, "get from another ring with the same data works");
}

# Only app changes
{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP2, group=>$GROUP1);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome', 'third new() works' );

    ok( $ring->get_password($USER, $REALM) eq $PWD, "get from another ring with changed app but same group works");
}

# Only group changes
my $sec_ring;
{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP1, group=>$GROUP2);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome', 'third new() works' );

    ok( ! defined($ring->get_password($USER, $REALM)), "changing group forces another password");

    # To test whether original won't be spoiled
    $ring->set_password($USER, $PWD2, $REALM);

    push @cleanups, sub {
        ok( $ring->clear_password($USER, $REALM) eq 1, "clearing");
    };
}

# App and group change
{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP2, group=>$GROUP3);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome', 'third new() works' );

    ok( ! defined($ring->get_password($USER, $REALM)), "changing group and app forces another password");

}

# Re-reading original to check whether it was properly kept
{
    my $ring = Passwd::Keyring::Gnome->new(app=>$APP1, group=>$GROUP1);

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome', 'second new() works' );

    ok( $ring->get_password($USER, $REALM) eq $PWD, "get original after changes in other group works");
}

# Cleanup
foreach my $cleanup (@cleanups) {
    $cleanup->();
}

