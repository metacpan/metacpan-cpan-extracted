#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for L<>  links.
#
# Copyright (c), December 2005, John McNamara, jmcnamara@cpan.org
#                              and Christopher J. Madsen
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 6;

my $style = 'mediawiki';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Links
    [
        "=pod\n\nL<http://www.perl.org>." => qq(http://www.perl.org.\n\n),
        'http'
    ],
    [
        "=pod\n\nL<Google|http://www.google.com>." =>
          qq([http://www.google.com Google].\n\n),
        'http with text'
    ],
    [
        "=pod\n\nL<Google(s)|https://www.google.com>." =>
          qq([https://www.google.com Google(s)].\n\n),
        'https with text'
    ],
    [
        qq(=pod\n\nL</"METHODS">) => qq([[#METHODS|"METHODS"]]\n\n),
        'Internal link'
    ],
    [
        qq(=pod\n\nL<Other::Module>) => qq([[Other::Module]]\n\n),
        'Other::Module'
    ],
    [
        qq(=pod\n\nL<Other::Module/"METHODS">) =>
          qq([[Other::Module#METHODS|"METHODS" in Other::Module]]\n\n),
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
        my $name   = $test_ref->[2];

        $pod =~ s/=pod\n\n//;
        $pod = "=pod\n\n=head1 Test " . $test++ . " $name\n\n$pod";

        $parser->parse_string_document( $pod );
    }
}


__END__

