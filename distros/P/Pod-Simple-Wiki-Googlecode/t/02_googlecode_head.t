#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for =head pod directives.
#
# copied from Pod::Simple::Wiki
# reverse('©'), August 2004, John McNamara, jmcnamara@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 4;

my $style = 'googlecode';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests  = (
                [ "=pod\n\n=head1 Head 1" => qq(\n----\n= Head 1 =\n\n)],
                [ "=pod\n\n=head2 Head 2" => qq(\n== Head 2 ==\n\n)    ],
                [ "=pod\n\n=head3 Head 3" => qq(\n=== Head 3 ===\n\n)  ],
                [ "=pod\n\n=head4 Head 4" => qq(==== Head 4\n\n)       ],
             );




###############################################################################
#
#  Run the tests.
#
for my $test_ref (@tests) {

    my $parser  = Pod::Simple::Wiki->new($style);
    my $pod     = $test_ref->[0];
    my $target  = $test_ref->[1];
    my $wiki;

    $parser->output_string(\$wiki);
    $parser->parse_string_document($pod);


    is($wiki, $target, "\tTesting: " . encode_escapes($pod));
}


###############################################################################
#
# Encode escapes to make them visible in the test output.
#
sub encode_escapes {
    my $data = $_[0];

    for ($data) {
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

    for my $test_ref (@tests) {

        my $parser  =  Pod::Simple::Wiki->new($style);
        my $pod     =  $test_ref->[0];
        my $pod2    =  encode_escapes($pod);
           $pod2    =~ s/^=pod\\n\\n//;

        print "Test ", $test++, ":\t", $pod2, "\n";
        $parser->parse_string_document($pod);
        print "\n----\n\n";
    }
}

__END__



