#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Test::XML;
use File::Slurp qw(slurp);
use TAP::Harness;
use IO::Scalar;

###############################################################################
# Figure out how many tests we have to run.
#
# *MANY* thanks Andy Armstrong et al. for the fabulous set of tests in
# Test::Harness. :)
my @tests = grep { -f $_ } <t/data/tests/*>;
plan tests => scalar(@tests);

###############################################################################
# Run each of the tests in turn, and compare the output to the expected JUnit
# output.
foreach my $test (@tests) {
    (my $junit = $test) =~ s{/tests/}{/tests/junit/};

    my $received = '';
    my $fh       = IO::Scalar->new(\$received);
    eval {
        my $harness = TAP::Harness->new( {
            stdout          => $fh,
            merge           => 1,
            formatter_class => 'TAP::Formatter::JUnit',
        } );
        $harness->runtests($test);
    };

    my $expected = slurp($junit);

    # Compare results (bearing in mind that some tests produce zero output, and
    # thus cannot be parsed as XML)
    if ($received || $expected) {
        is_xml $received, $expected, $test;
    }
    else {
        is $received, $expected, $test;
    }
}
