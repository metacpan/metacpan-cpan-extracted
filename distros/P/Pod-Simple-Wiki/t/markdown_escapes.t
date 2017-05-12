#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for =over ... =back regions.
#
# Copyright 2003-2014, John McNamara, jmcnamara@cpan.org, Daniel T. Staal,
# DStaal@usa.net
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 4;

my $style = 'markdown';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests;

#
# Extract tests embedded in _DATA_ section.
#
my $test_no = 1;
my $pod;
my $test = '';
my $todo = '';
my $name;

while ( <DATA> ) {
    if ( /^#/ ) {
        $name = $1 if /NAME: (.*)/;
        $todo = $1 if /TODO: (.*)/;

        if ( $test ) {
            if ( $test_no % 2 ) {
                $pod = $test;
            }
            else {
                push @tests, [ $pod, $test, $name, $todo ];
                $name = '';
                $todo = '';
            }

            $test = '';
            $test_no++;
        }
        next;
    }
    s/\r//;        # Remove any \r chars that slip in.
    s/\\t/\t/g;    # Sub back in any escaped tabs.
    s/\\#/#/g;     # Sub back in any escaped comments.
    $test .= $_;
}


###############################################################################
#
#  Run the tests.
#
for my $test_ref ( @tests ) {

    my $parser = Pod::Simple::Wiki->new( $style );
    my $pod    = $test_ref->[0];
    my $target = $test_ref->[1];
    my $name   = $test_ref->[2];
    my $todo   = $test_ref->[3];
    my $wiki;

    $parser->output_string( \$wiki );
    $parser->parse_string_document( $pod );

    local $TODO = $todo;
    is( $wiki, $target, " \t" . $name );
}


###############################################################################
#
# Output the tests for visual testing in the wiki.
#
sub output_tests {

    my $test = 1;

    print "\n\n";

    for my $test_ref ( @tests ) {

        my $parser = Pod::Simple::Wiki->new( $style );
        my $pod    = $test_ref->[0];
        my $name   = $test_ref->[2];

        $name =~ s/</&lt;/g;
        $name =~ s/>/&gt;/g;

        print "h2. Test ", $test++, ":\t", $name, "\n\n";
        $parser->parse_string_document( $pod );
    }
}

__DATA__
################################################################################
#
# Test data.
#
################################################################################
#
# NAME: Test for asterisks.
#
=pod

This text has *asterisks* that need to be escaped.

=cut
#
#
# Expected output.
#
#
This text has \*asterisks\* that need to be escaped.

################################################################################
#
# NAME: Test for underlines.
#
=pod

This text has _underlines_ that need to be escaped.

=cut
#
#
# Expected output.
#
#
This text has \_underlines\_ that need to be escaped.

################################################################################
#
# NAME: Test for backticks.
#
=pod

This text has `backticks` that need to be escaped.

=cut
#
#
# Expected output.
#
#
This text has \`backticks\` that need to be escaped.

################################################################################
#
# NAME: Test for backslash.
#
=pod

This text has \backslashes\ that need to be escaped.

=cut
#
#
# Expected output.
#
#
This text has \\backslashes\\ that need to be escaped.

###############################################################################
#
# End
#
###############################################################################
