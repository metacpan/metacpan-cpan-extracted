#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "These tests don't run well under root"
      unless $>;
}

BEGIN { use_ok("Passwd::Keyring::Auto"); }

# Method presence
{
    my $keyring = Passwd::Keyring::Auto::get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"test 50");
    can_ok($keyring, "set_password");
    can_ok($keyring, "get_password");
    can_ok($keyring, "is_persistent");
}

# Simple store&read plus rewriting check
{
    my $keyring = Passwd::Keyring::Auto::get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"test 50");
    #isa_ok($keyring, 'Keyring');
    $keyring->set_password("testuser", "testpwd", "testapp");
    ok( "testpwd" eq $keyring->get_password("testuser", "testapp") );
    $keyring->set_password("testuser", "testpwd2", "testapp");
    ok( "testpwd2" eq $keyring->get_password("testuser", "testapp") );
    $keyring->clear_password("testuser", "testapp");
    ok( ! defined ( $keyring->get_password("testuser", "testapp") ));
}

# Saving many passwords, then recovering them, then recovering via another object
{
    my $app = "testapp";
    my @users = map { $_ . time } (
        "aaa",
        "bbb",
        "ccc ddd",
        'eee-fff-ggg@hh.zz.com');
    my @pwds = map { $_ . time } (
        "secret", 
        "#ugly ^passą",
        "----->>>>",
        "[in]");

    my $keyring1 = Passwd::Keyring::Auto::get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"test 50");
    #isa_ok($keyring1, 'Keyring');
    foreach my $idx (0 .. $#users) {
        $keyring1->set_password($users[$idx], $pwds[$idx], $app);
    }

    foreach my $idx (0 .. $#users) {
        ok( $keyring1->get_password($users[$idx], $app));
        ok( $pwds[$idx] eq $keyring1->get_password($users[$idx], $app));
    }

    my $keyring2 = Passwd::Keyring::Auto::get_keyring(
        app_name=>"Passwd::Keyring::Auto unit tests", group=>"test 50");

    is(ref($keyring2), ref($keyring1), "Got the same keyring on second invocation");

  SKIP: {

        skip "Using non-persistent keyring", 2*scalar(@users)
          unless $keyring2->is_persistent;

        foreach my $idx (0 .. $#users) {
            if($keyring2->is_persistent) {
                ok( $pwds[$idx] eq $keyring2->get_password($users[$idx], $app));
            } else {
                ok( ! defined($keyring2->get_password($users[$idx], $app)));
            }
        }

        $keyring1->clear_password($_, $app) foreach @users;
        foreach my $idx (0 .. $#users) {
            ok( ! defined($keyring2->get_password($users[$idx], $app)));
        }
    }

}

done_testing;
