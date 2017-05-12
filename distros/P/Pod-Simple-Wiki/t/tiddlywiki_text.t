#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for I<>, B<>, C<> etc., formatting codes.
#
# Copyright (c), August 2004, John McNamara, jmcnamara@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 24;

my $style = 'tiddlywiki';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests = (

    # Simple formatting tests
    [ "=pod\n\nxxC<-->xx"  => qq(xx{{{--}}}xx\n\n),           'Escape C<-->' ],
    [ "=pod\n\nxx--xx--"   => qq(xx{{{--}}}xx{{{--}}}\n\n),   'Escape --' ],
    [ "=pod\n\nxx---xx---" => qq(xx{{{---}}}xx{{{---}}}\n\n), 'Escape ---' ],
    (
        map {
            [
                "=pod\n\nxx$_${_}xx$_$_" => qq(xx{{{$_$_}}}xx{{{$_$_}}}\n\n),
                "Escape $_$_"
            ]
        } qw( - / ' _ ^ > ~ @ )
    ),
    [
        "=pod\n\nxxE<gt>E<gt>xxE<lt>E<lt>xxE<sol>E<sol>xx" =>
          qq(xx{{{>>}}}xx{{{<<}}}xx{{{//}}}xx\n\n),
        'Escape doubles E<gt> E<lt> E<sol>'
    ],
    [ "=pod\n\nxx/E<sol>/xx" => qq(xx{{{///}}}xx\n\n), 'Escape /E<sol>/' ],

    # WikiWords RT#60650
    [ "=pod\n\nWikiWord"    => qq(~WikiWord\n\n),    'Escape WikiWord' ],
    [ "=pod\n\nWikiWWW"     => qq(~WikiWWW\n\n),     'Escape -WikiWWW' ],
    [ "=pod\n\nxxWikiWord"  => qq(xxWikiWord\n\n),   'No Escape xxWikiWord' ],
    [ "=pod\n\n01WikiWord"  => qq(01WikiWord\n\n),   'No Escape 01WikiWord' ],
    [ "=pod\n\nxx_WikiWord" => qq(xx_~WikiWord\n\n), 'Escape xx_WikiWord' ],
    [ "=pod\n\nWikiWord2"   => qq(~WikiWord2\n\n),   'Escape WikiWord2' ],
    [ "=pod\n\nWiki2Word"   => qq(~Wiki2Word\n\n),   'Escape Wiki2Word' ],
    [ "=pod\n\nWiki-Word"   => qq(~Wiki-Word\n\n),   'Escape Wiki-Word' ],
    [ "=pod\n\n-WikiWord"   => qq(-~WikiWord\n\n),   'Escape -WikiWord' ],
    [ "=pod\n\n-Wiki-Word"  => qq(-~Wiki-Word\n\n),  'Escape -Wiki-Word' ],
    [
        "=pod\n\n-Wiki-Word+Wiki-Word" => qq(-~Wiki-Word+~Wiki-Word\n\n),
        'Escape -Wiki-Word+Wiki-Word'
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

