#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for L<>  links.
#
# Copyright (c), December 2005, John McNamara, jmcnamara@cpan.org,
#                              Christopher J. Madsen, and Daniel T. Staal
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 4;

my $style = 'markdown';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Links
    [
        qq(=pod\n\nL<http://www.perl.org>.) =>
          qq{[http://www.perl.org](http://www.perl.org).\n\n},
        'http'
    ],
    [
        qq(=pod\n\nL</"METHODS">) => qq{["METHODS"](#METHODS)\n\n},
        'Internal link'
    ],
    [
        qq(=pod\n\nL<Other::Module>) => qq{[Other::Module](Other::Module)\n\n},
        'Other::Module'
    ],
    [
        qq(=pod\n\nL<Other::Module/"METHODS">) =>
          qq{["METHODS" in Other::Module](Other::Module#METHODS)\n\n},
        'Other::Module/METHODS'
    ],

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
} ## end for my $test_ref ( @tests)


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
        my $name   = $test_ref->[2];

        $pod =~ s/=pod\n\n//;
        $pod = "=pod\n\n=head1 Test " . $test++ . " $name\n\n$pod";

        $parser->parse_string_document( $pod );
    } ## end for my $test_ref ( @tests)
} ## end sub output_tests


__END__

