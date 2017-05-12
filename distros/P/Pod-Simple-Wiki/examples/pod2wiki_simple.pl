#!/usr/bin/perl -w

#######################################################################
#
# A simple pod2wiki filter demo. See pod2wiki.pl for a more complete
# utility.
#
# reverse('©'), May 2003, John McNamara, jmcnamara@cpan.org
#

use strict;
use Pod::Simple::Wiki;


my $parser = Pod::Simple::Wiki->new();


if (defined $ARGV[0]) {
    open IN, $ARGV[0]  or die "Couldn't open $ARGV[0]: $!\n";
} else {
    *IN = *STDIN;
}

if (defined $ARGV[1]) {
    open OUT, ">$ARGV[1]" or die "Couldn't open $ARGV[1]: $!\n";
} else {
    *OUT = *STDOUT;
}


$parser->output_fh(*OUT);
$parser->parse_file(*IN);


__END__
