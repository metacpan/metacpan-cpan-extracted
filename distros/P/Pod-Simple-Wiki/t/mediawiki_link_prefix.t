#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for the CPANification of L<> links.
#
# Copyright (c), October 2012, Peter Hallam, pragmatic@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 2;

my $style = 'mediawiki';
my $opts = { link_prefix => 'http://search.cpan.org/perldoc?' };

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Links
    [
        qq(=pod\n\nL<Other::Module>) =>
          qq([http://search.cpan.org/perldoc?Other::Module Other::Module]\n\n),
        'Other::Module'
    ],
    [
        qq(=pod\n\nL<Other::Module/"METHODS">) =>
qq([http://search.cpan.org/perldoc?Other::Module#METHODS "METHODS" in Other::Module]\n\n),
        'Other::Module/METHODS'
    ],

);


###############################################################################
#
#  Run the tests.
#
for my $test_ref ( @tests ) {

    my $parser = Pod::Simple::Wiki->new( $style, $opts );
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

        my $parser = Pod::Simple::Wiki->new( $style, $opts );
        my $pod    = $test_ref->[0];
        my $name   = $test_ref->[2];

        $pod =~ s/=pod\n\n//;
        $pod = "=pod\n\n=head1 Test " . $test++ . " $name\n\n$pod";

        $parser->parse_string_document( $pod );
    }
}


__END__
