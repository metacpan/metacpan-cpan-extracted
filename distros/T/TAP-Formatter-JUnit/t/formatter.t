#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Test::XML;
use File::Slurp qw(slurp);
use TAP::Harness;
use IO::Scalar;
use version;

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
    # Where is the JUnit output we should be expecting?
    (my $junit = $test) =~ s{/tests/}{/tests/junit/};

    # Process TAP, and turn it into JUnit
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

    # OVER-RIDE: With Test::Harness prior to v3.43, the "bailout" test would
    # result in zero/no output.  This was fixed in Test::Harness v3.43_0*
    # development releases, but WE need to watch for and provide accommodations
    # for newer/older versions.
    unless (version->parse($TAP::Harness::VERSION) > version->parse(3.43)) {
      if ($test =~ /bailout/) {
        $expected = '';
      }
    }

    # Compare results (bearing in mind that some tests produce zero output, and
    # thus cannot be parsed as XML)
    if ($received || $expected) {
        is_xml $received, $expected, $test
          or diag "GOT: ", explain($received);
    }
    else {
        is $received, $expected, $test
          or diag "GOT: ", explain($received);
    }
}
