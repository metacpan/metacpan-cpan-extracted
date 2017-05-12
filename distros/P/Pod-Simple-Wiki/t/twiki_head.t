#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for =head pod directives.
#
# Copyright (c), March 2005, Sam Tregar, sam@tregar.com
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 4;

my $style = 'twiki';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (
    [ "=pod\n\n=head1 Head 1" => qq(---+ Head 1\n\n) ],
    [ "=pod\n\n=head2 Head 2" => qq(---++ Head 2\n\n) ],
    [ "=pod\n\n=head3 Head 3" => qq(---+++ Head 3\n\n) ],
    [ "=pod\n\n=head4 Head 4" => qq(---++++ Head 4\n\n) ],
);


###############################################################################
#
#  Run the tests.
#
for my $test_ref ( @tests ) {

    my $parser = Pod::Simple::Wiki->new( $style );
    my $pod    = $test_ref->[0];
    my $target = $test_ref->[1];
    my $wiki;

    $parser->output_string( \$wiki );
    $parser->parse_string_document( $pod );


    is( $wiki, $target, "\tTesting: " . encode_escapes( $pod ) );
}


###############################################################################
#
# Encode escapes to make them visible in the test output.
#
sub encode_escapes {
    my $data = $_[0];

    for ( $data ) {
        s/\t/\\t/g;
        s/\n/\\n/g;
    }

    return $data;
}


###############################################################################
#
# Output the tests for visual testing in the wiki.
#
sub output_tests {

    my $test = 1;

    print "\n----\n\n";

    for my $test_ref ( @tests ) {

        my $parser = Pod::Simple::Wiki->new( $style );
        my $pod    = $test_ref->[0];
        my $pod2   = encode_escapes( $pod );
        $pod2 =~ s/^=pod\\n\\n//;
        $pod2 =~ s/</&lt;/g;
        $pod2 =~ s/>/&gt;/g;

        print "Test ", $test++, ":\t", $pod2, "\n";
        $parser->parse_string_document( $pod );
        print "\n----\n\n";
    }
}

__END__



