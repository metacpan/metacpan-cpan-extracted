#!/usr/bin/env perl -w

#This script has been taken from a forum somewhere in the vast Internet space :)
#Its purpose is to generate the HTML from POD and apply some CSS as it will look like on CPAN
#Typical use: perl pod2cpanhtml.pl lib/PDF/Table.pm pdftable.html

use strict;
use Pod::Simple::HTML;

my $parser = Pod::Simple::HTML->new();

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

$parser->index(1);
$parser->html_css('http://search.cpan.org/s/style.css');

$parser->output_fh(*OUT);
$parser->parse_file(*IN);

