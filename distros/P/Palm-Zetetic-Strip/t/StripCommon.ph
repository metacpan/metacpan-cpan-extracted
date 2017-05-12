#!/usr/bin/perl -w

use strict;

sub test
{
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}


sub get_number_of_tests
{
    return 28;
}

sub run_common_tests
{
    my ($start, $dir, $version, $force_version) = @_;
    my $strip;
    my @systems;
    my @accounts;
    my $account;
    my $i;

    $i = $start;
    eval "use Palm::Zetetic::Strip";
    test($i++, !$@, "Couldn't load module");

    $strip = new Palm::Zetetic::Strip();
    test($i++, $strip, "Couldn't create new object");

    if ($force_version)
    {
        $strip->set_directory($dir, $version);
    }
    else
    {
        $strip->set_directory($dir);
    }

    test($i++, $strip->get_strip_version()->get_version_string() eq $version,
         "Version should be ${version}");
    test($i++, ! $strip->set_password("wrong password"),
         "Should not set wrong password");
    test($i++, $strip->set_password("setec astronomy"),
         "Should set correct password");

    $strip->load();
    @systems = $strip->get_systems();
    test($i++, (@systems == 3), "Wrong number of systems");
    test($i++, ($systems[0]->get_name() eq "First"), "First category wrong");
    test($i++, ($systems[1]->get_name() eq "Second"),
         "Second category wrong");
    test($i++, ($systems[2]->get_name() eq "Unfiled"),
         "Third category wrong");


    @accounts = $strip->get_accounts($systems[0]);
    test($i++, (@accounts == 2), "Wrong number of accounts");

    $account = $accounts[0];
    test($i++, ($account->get_system() eq "sys 1"), "First system wrong");
    test($i++, ($account->get_username() eq "login 1"), "First username wrong");
    test($i++, ($account->get_password() eq "password 1"),
         "First password wrong");
    test($i++, ($account->get_comment() eq "note 1"), "First comment wrong");

    $account = $accounts[1];
    test($i++, ($account->get_system() eq ""), "Second system wrong");
    test($i++, ($account->get_username() eq "login 2"),
         "Second username wrong");
    test($i++, ($account->get_password() eq "password 2"),
         "Second password wrong");
    test($i++, ($account->get_comment() eq ""), "Second comment wrong");

    @accounts = $strip->get_accounts($systems[1]);
    test($i++, (@accounts == 2), "Wrong number of accounts");

    $account = $accounts[0];
    test($i++, ($account->get_system() eq "sys 3"), "Third system wrong");
    test($i++, ($account->get_username() eq "login 3"),
         "Third username wrong");
    test($i++, ($account->get_password() eq "password 3"),
         "Third password wrong");
    test($i++, ($account->get_comment() eq ""), "Third comment wrong");

    $account = $accounts[1];
    test($i++, ($account->get_system() eq "sys 4"), "Fourth system wrong");
    test($i++, ($account->get_username() eq "login 4"),
         "Fourth username wrong");
    test($i++, ($account->get_password() eq "password 4\nline 2"),
         "Fourth password wrong");
    test($i++, ($account->get_comment() eq ""), "Fourth comment wrong");

    @accounts = $strip->get_accounts($systems[2]);
    test($i++, (@accounts == 0), "Wrong number of accounts");

    return $i;
}

1;
