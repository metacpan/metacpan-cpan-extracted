#!/usr/bin/env perl

# use this script to regenerate the test data files in t/perl Add a new file
# to t/perl/before and when you run this, a "highlighted" version will be
# created in t/perl/highlighted directory

use lib 't/lib';
use strict;
use warnings;
use TestHighlight ':all';

my $to_highlight = get_sample_perl_files();
my $total        = keys %$to_highlight;
my $current      = 0;

while ( my ( $orig, $new ) = each %$to_highlight ) {
    $current++;
    print "Processing $current out of $total ($orig)\n";
    my $highlighter = get_highlighter('Perl');
    my $highlighted = $highlighter->highlightText( slurp($orig) );

    open my $fh, '>', $new or die "Cannot open $new for writing: $!";
    print $fh $highlighted;
}
