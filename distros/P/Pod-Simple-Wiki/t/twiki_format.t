#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for I<>, B<>, C<> etc., formatting codes.
#
# Copyright (c), March 2005, Sam Tregar, sam@tregar.com
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 6;

my $style = 'twiki';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Simple formatting tests
    [ "=pod\n\nI<Foo>" => qq(_Foo_\n\n), 'Italic' ],
    [ "=pod\n\nB<Foo>" => qq(*Foo*\n\n), 'Bold' ],
    [ "=pod\n\nC<Foo>" => qq(=Foo=\n\n), 'Monospace' ],
    [ "=pod\n\nF<Foo>" => qq(_Foo_\n\n), 'Filename' ],

    # Nested formatting tests
    [ "=pod\n\nB<I<Foo>>" => qq(*_Foo_*\n\n), 'Bold Italic' ],
    [
        "=pod\n\nI<B<Foo>>" => qq(__Foo__\n\n),
        'Italic Bold',
        'Fix this later.'
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
    my $todo   = $test_ref->[3];
    my $wiki;

    $parser->output_string( \$wiki );
    $parser->parse_string_document( $pod );

    local $TODO = $todo;
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

