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
    return 10;
}

sub print_summary
{
    print "1..", get_number_of_tests(), "\n";
}

sub run_tests
{
    my ($start) = @_;
    my $version;
    my $i;

    $i = $start;
    eval "use Palm::Zetetic::Strip::Version";
    test($i++, !$@, "Couldn't load module");

    $version = new Palm::Zetetic::Strip::Version();
    test($i++, $version, "Couldn't create new object");
    test($i++, $version->get_version_string() eq "0.5i",
         "Default string is v0.5i");
    test($i++, $version->is_0_5i(), "Default is v0.5i");

    $version = new Palm::Zetetic::Strip::Version();
    $version->set_version_string("1.0");
    test($i++, $version->get_version_string() eq "1.0",
         "Set version string is v1.0");
    test($i++, $version->is_1_0(), "Set to v1.0");

    $version = new Palm::Zetetic::Strip::Version();
    $version->set_version_string("0.5i");
    test($i++, $version->get_version_string() eq "0.5i",
         "Set version string is v0.5i");
    test($i++, $version->is_0_5i(), "Set to v0.5i");

    $version = new Palm::Zetetic::Strip::Version();
    $version->set_version_string("x.xx");
    test($i++, $version->get_version_string() eq "0.5i",
         "Unknown version string is v0.5i");
    test($i++, $version->is_0_5i(), "Unknown set to v0.5i");
}

print_summary;
run_tests(1);

1;
