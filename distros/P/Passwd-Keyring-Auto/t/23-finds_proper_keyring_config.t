#!perl

use strict;
use warnings;
use Test::More;
use File::Temp;

BEGIN {
    plan skip_all => 'these tests are for release testing (they are strongly dependant on environment setup)'
      unless $ENV{RELEASE_TESTING};
}

BEGIN { use_ok("Passwd::Keyring::Auto", qw(get_keyring)) };

my $kwalletd_present = 0;
eval {
    open(my $ps, "ps -eo fname |") or die $@;
    while(<$ps>) {
        if(/kwalletd/) {
            $kwalletd_present = 1;
        }
    }
} or warn "Can't test processes: $@\n";

# First config , default
SKIP: {
    skip "Not a Gnome session", 3 unless $ENV{GNOME_DESKTOP_SESSION_ID} || ($ENV{DESKTOP_SESSION} || '') =~ /^(gnome.*|ubuntu)$/i;
    eval { require Passwd::Keyring::Gnome };
    skip "Passwd::Keyring::Gnome not installed", 3 if $@;

    my $ring = get_keyring(config=>"t/23-config-gnomeish.cfg");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::Gnome", ref($ring) . " - made using 23-config-gnomeish (default)");
}

# First config, app-specific 1
SKIP: {
    eval { require Passwd::Keyring::PWSafe3 };
    skip "Passwd::Keyring::PWSafe3 not installed", 3 if $@;

    my $ring = get_keyring(config=>"t/23-config-gnomeish.cfg", app=>"Passwd::Keyring test - PwApp");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::PWSafe3", ref($ring) . " - made using 23-config-gnomeish (Passwd::Keyring test - PwApp)");
}

# First config, app-specific 2 (+ overriding ENV)
SKIP: {
    eval { require Passwd::Keyring::PWSafe3 };
    skip "Passwd::Keyring::PWSafe3 not installed", 3 if $@;

    local $ENV{PASSWD_KEYRING_CONFIG} = "t/23-config-kdeish.cfg"; # Should not be used
    my $ring = get_keyring(config=>"t/23-config-gnomeish.cfg", app=>"Passwd::Keyring test - Memmy");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::Memory", ref($ring) . " - made using 23-config-gnomeish (Passwd::Keyring test - Memmy)");
}

# First config, app-specific 1 (and only ENV)
SKIP: {
    eval { require Passwd::Keyring::PWSafe3 };
    skip "Passwd::Keyring::PWSafe3 not installed", 3 if $@;

    local $ENV{PASSWD_KEYRING_CONFIG} = "t/23-config-gnomeish.cfg"; 
    my $ring = get_keyring(app=>"Passwd::Keyring test - PwApp");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::PWSafe3", ref($ring) . " - made using 23-config-gnomeish (Passwd::Keyring test - PwApp)");
}

# Second config, default
SKIP: {
    eval { require Passwd::Keyring::KDEWallet };
    skip "Passwd::Keyring::KDEWallet not installed", 3 if $@;
    skip ("kwalletd not running, start it (for example by spawning kwalletmanager)to use KDE Wallet", 3) unless $kwalletd_present;

    my $ring = get_keyring(config=>"t/23-config-kdeish.cfg", app=>"Passwd::Keyring test - SomeApp",
                           master_password=>"87654321");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::KDEWallet", ref($ring) . " - made using 23-config-kdeish (default - Passwd::Keyring test - SomeApp)");
}

# Second config, app-specific
SKIP: {
    eval { require Passwd::Keyring::KDEWallet };
    skip "Passwd::Keyring::KDEWallet not installed", 3 if $@;
    skip ("kwalletd not running, start it (for example by spawning kwalletmanager)to use KDE Wallet", 3) unless $kwalletd_present;

    my $ring = get_keyring(config=>"t/23-config-kdeish.cfg", app=>"Passwd::Keyring test - PwApp",
                           master_password=>"87654321");
    ok($ring, "Got some keyring");

    isa_ok($ring, "Passwd::Keyring::PWSafe3", ref($ring) . " - made using 23-config-kdeish (Passwd::Keyring test - PwApp)");
}

done_testing;

