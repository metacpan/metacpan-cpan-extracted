#!perl -T

use strict;
use warnings;
use Test::More;
use File::Temp;

BEGIN { use_ok("Passwd::Keyring::Auto", qw(get_keyring)) };

# Under Gnome good keyring should be picked
SKIP: {
    skip "Not a Gnome session", 3
      unless $ENV{GNOME_DESKTOP_SESSION_ID} || ($ENV{DESKTOP_SESSION} || '') =~ /^(gnome.*|ubuntu)$/i;
    skip "Running as root", 3
      unless $>;
    eval { require Passwd::Keyring::Gnome };
    skip "Passwd::Keyring::Gnome not installed", 3
      if $@;

    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests",
        group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under Gnome we should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::Gnome", "Under Gnome we should get Gnome keyring");
}

# ... but not if it is forbidden
SKIP: {
    skip "Not a Gnome session", 3 unless $ENV{GNOME_DESKTOP_SESSION_ID} || ($ENV{DESKTOP_SESSION} || '') =~ /^(gnome.*|ubuntu)$/i;
    eval { require Passwd::Keyring::Gnome };
    skip "Passwd::Keyring::Gnome not installed", 3 if $@;

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
                           forbid=>"Gnome");
    ok($ring, "Got some keyring");

    unlike(ref($ring), qr/::Gnome$/, "We should respect forbid=Gnome");
}

# Under KDE we should get KDE Wallet
SKIP: {
    skip "Not a KDE desktop session", 3 
      unless ($ENV{DESKTOP_SESSION} || '') =~ /^kde/;
    skip "Running as root", 3
      unless $>;
    eval { require Passwd::Keyring::KDEWallet };
    skip "Passwd::Keyring::KDEWallet not installed", 3 if $@;

    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
        forbid=>["Gnome"]);
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under Linux desktop we should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::KDEWallet", "Under KDE we should get KDE keyring");
}

# ... unless forbidden
SKIP: {
    skip "Not a KDE desktop session", 3 
      unless ($ENV{DESKTOP_SESSION} || '') =~ /^kde/;
    eval { require Passwd::Keyring::KDEWallet };
    skip "Passwd::Keyring::KDEWallet not installed", 3
      if $@;

    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
        forbid=>["KDEWallet"]);
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under Linux desktop we should get persistent keyring");

    unlike(ref($ring), qr/::KDEWallet/, "We should respect forbid under KDE");
}

SKIP: {
    skip "Not a desktop session", 3 
      unless ($ENV{DESKTOP_SESSION});

    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
        "forbid"=>["KDEWallet", "Gnome"]);
    ok($ring, "Got some keyring");

    unlike(ref($ring), qr/::KDEWallet/, "We should respect forbid");
    unlike(ref($ring), qr/::Gnome/, "We should respect forbid");
}

SKIP: {
    eval { require Passwd::Keyring::PWSafe3; };
    skip "Passwd::Keyring::PWSafe3 not installed", 3 if $@;

    my ($fh, $filename) = File::Temp::tempfile();
    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
        master_password=>"Very Secret Password",
        file=>$filename,
        force=>"PWSafe3");
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "We should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::PWSafe3", "With PASSWD_KEYRING_FORCE=PWSafe3, got " . ref($ring));
}


done_testing;

