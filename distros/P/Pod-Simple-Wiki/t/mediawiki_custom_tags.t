#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for custom formatting codes.
#
# Copyright (c), October 2012, Peter Hallam, pragmatic@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 1;

my $style = 'mediawiki';
my $opts  = {
    custom_tags => {
        '<pre>'  => "<syntaxhighlight lang=\"perl\">\n",
        '</pre>' => "\n</syntaxhighlight>\n\n",
    }
};

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Simple formatting tests
    [
        "=pod\n\n Foo" =>
          qq(<syntaxhighlight lang=\"perl\">\n Foo\n</syntaxhighlight>\n\n),
        'Syntaxhighlight code'
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

    print "\n\n";

    for my $test_ref ( @tests ) {

        my $parser = Pod::Simple::Wiki->new( $style, $opts );
        my $pod    = $test_ref->[0];
        my $name   = $test_ref->[2];

        $pod =~ s/=pod\n\n//;
        $pod = "=pod\n\n=head2 Test " . $test++ . " $name\n\n$pod";

        $parser->parse_string_document( $pod );
    }
}


__END__

