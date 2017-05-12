#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for =head1 pod sentence-cased directives.
#
# Copyright (c), October 2012, Peter Hallam, pragmatic@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 2;

my $style = 'mediawiki';
my $opts = { sentence_case_headers => 1 };

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (
    [ "=pod\n\n=head1 DESCRIPTION"         => qq(==Description==\n) ],
    [ "=pod\n\n=head1 COPYRIGHT & LICENSE" => qq(==Copyright & license==\n) ],
);


###############################################################################
#
#  Run the tests.
#
for my $test_ref ( @tests ) {

    my $parser = Pod::Simple::Wiki->new( $style, $opts );
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

        my $parser = Pod::Simple::Wiki->new( $style, $opts );
        my $pod    = $test_ref->[0];
        my $pod2   = encode_escapes( $pod );
        $pod2 =~ s/^=pod\\n\\n//;

        print "Test ", $test++, ":\t", $pod2, "\n";
        $parser->parse_string_document( $pod );
        print "\n----\n\n";
    }
}

__END__
