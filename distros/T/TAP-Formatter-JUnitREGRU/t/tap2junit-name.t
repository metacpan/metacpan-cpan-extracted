#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use File::Slurp qw(slurp);
use File::Spec;

###############################################################################
# TEST: Run "tap2junit" and let it name the test in the JUnit automatically.
tap2junit_default_name: {
    my $test_file = 't/data/tap/simple';
    my $xml_file  = "$test_file.xml";

    _tap2junit($test_file);
    my $xml = slurp($xml_file);

    unlink $xml_file;

    like $xml, qr/<testsuite[^>]+name="data_tap_simple"/m,
        'default name based on TAP filename';
}

###############################################################################
# TEST: Run "tap2junit" with "--name" and rename a test
tap2junit_name: {
    my $test_file = 't/data/tap/simple';
    my $xml_file  = "$test_file.xml";

    _tap2junit($test_file, '--name', 'foo');
    my $xml = slurp($xml_file);

    unlink $xml_file;

    like $xml, qr/<testsuite[^>]+name="foo"/m, 'name explicitly provided';
}

sub _tap2junit {
    my @args = @_;
    my $null = File::Spec->devnull();
    system(qq{ $^X -Iblib/lib blib/script/tap2junit @args 2>$null });
}
