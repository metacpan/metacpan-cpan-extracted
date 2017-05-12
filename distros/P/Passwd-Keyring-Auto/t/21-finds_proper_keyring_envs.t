#!perl -T

use strict;
use warnings;
use Test::More;
use File::Temp;

BEGIN { use_ok("Passwd::Keyring::Auto", qw(get_keyring)) };

# Minimal env grabbing
my @diagn;

foreach my $variable (qw(DESKTOP_SESSION)) {
    push @diagn, "$variable=$ENV{$variable}" if $ENV{$variable};
}
foreach my $variable (qw(DISPLAY GNOME_DESKTOP_SESSION_ID DBUS_SESSION_BUS_ADDRESS GNOME_KEYRING_CONTROL GNOME_KEYRING_PID)) {
    push @diagn, "$variable present" if $ENV{$variable};
}
diag(join(", ", @diagn));

# Under Gnome good keyring should be picked
SKIP: {
    skip "Not a Gnome session", 3
      unless $ENV{GNOME_DESKTOP_SESSION_ID} || ($ENV{DESKTOP_SESSION} || '') =~ /^(gnome.*|ubuntu)$/i;
    skip "Running as root", 3
      unless $>;
    eval { require Passwd::Keyring::Gnome };
    skip "Passwd::Keyring::Gnome not installed", 3
      if $@;

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under Gnome we should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::Gnome", "Under Gnome we should get Gnome keyring");
}

# ... but not if it is forbidden
SKIP: {
    skip "Not a Gnome session", 3 
      unless $ENV{GNOME_DESKTOP_SESSION_ID} || ($ENV{DESKTOP_SESSION} || '') =~ /^(gnome.*|ubuntu)$/i;
    eval { require Passwd::Keyring::Gnome };
    skip "Passwd::Keyring::Gnome not installed", 3 if $@;

    local $ENV{PASSWD_KEYRING_FORBID} = 'Gnome';

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    unlike(ref($ring), qr/::Gnome$/, "We should respect FORBID under Gnome");
}

# Under KDE we should get KDE Wallet
SKIP: {
    skip "Not a KDE desktop session", 3
      unless ($ENV{DESKTOP_SESSION} || '') =~ /^kde/;
    skip "Running as root", 3
      unless $>;
    eval { require Passwd::Keyring::KDEWallet };
    skip "Passwd::Keyring::KDEWallet not installed", 3
      if $@;

    local $ENV{PASSWD_KEYRING_FORBID} = 'Gnome';

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
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

    local $ENV{PASSWD_KEYRING_FORBID} = 'KDEWallet';

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under Linux desktop we should get persistent keyring");

    unlike(ref($ring), qr/::KDEWallet/, "We should respect FORBID under KDE");
}

SKIP: {
    skip "Not a desktop session", 3 
      unless ($ENV{DESKTOP_SESSION});
    skip "Running as root", 3
      unless $>;

    local $ENV{PASSWD_KEYRING_FORBID} = 'KDEWallet Gnome';

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    unlike(ref($ring), qr/::KDEWallet/, "We should respect FORBID");
    unlike(ref($ring), qr/::Gnome/, "We should respect FORBID");
}

SKIP: {
    skip "Not a Mac", 3
      unless $^O eq 'darwin';
    skip "Running as root", 3
      unless $>;
    eval { require Passwd::Keyring::OSXKeychain };
    skip "Passwd::Keyring::OSXKeychain not installed", 3 if $@;

    my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto");
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "Under OS/X we should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::OSXKeychain", "Under darwin we should get OSXKeychain keyring");
}

SKIP: {
    eval { require Passwd::Keyring::PWSafe3; };
    skip "Passwd::Keyring::PWSafe3 not installed", 3
      if $@;

    local $ENV{PASSWD_KEYRING_FORCE} = "PWSafe3";
    my ($fh, $filename) = File::Temp::tempfile();
    my $ring = get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"Passwd::Keyring::Auto",
        master_password=>"Very Secret Password",
        file=>$filename);
    ok($ring, "Got some keyring");

    ok($ring->is_persistent, "We should get persistent keyring");

    isa_ok($ring, "Passwd::Keyring::PWSafe3", "With PASSWD_KEYRING_FORCE=PWSafe3, got " . ref($ring));
}

done_testing;

