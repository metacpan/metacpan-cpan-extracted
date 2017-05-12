#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for L<> link formatting codes.
#
# Copyright (c), January 2011, John McNamara, jmcnamara@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 4;

my $style = 'confluence';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Simple URLs.
    [ "=pod\n\nL<www.perl.com>" => qq([www.perl.com]\n\n), 'Simple URL' ],
    [
        "=pod\n\nL<Perl|www.perl.com>" => qq([Perl|www.perl.com]\n\n),
        'Simple URL with text'
    ],
    [ "=pod\n\nL<Document>" => qq([Document]\n\n), 'Simple doc link' ],
    [ "=pod\n\nL<Doc Link>" => qq([Doc Link]\n\n), 'Simple doc link' ],
);


###############################################################################
#
#  Run the tests.
#
for my $test_ref ( @tests ) {

    my $parser = Pod::Simple::Wiki->new( $style );
    my $pod    = $test_ref->[0];
    my $target = $test_ref->[1];
    my $name   = $test_ref->[2];
    my $wiki;

    $parser->output_string( \$wiki );
    $parser->parse_string_document( $pod );

    is( $wiki, $target, "\tTesting: $name" );
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

        $pod =~ s/=pod\n\n//;
        $pod = "=pod\n\n=head2 Test " . $test++ . " $name\n\n$pod";

        $parser->parse_string_document( $pod );
    }
}


__END__

