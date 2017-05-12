#!/usr/bin/perl
#
# sort of like GNU grep
#

use strict;
use warnings;

use File::Slurp;
use Search::Tools;

my $usage = "$0 'query' file(s) \n";

my $query = shift @ARGV or die $usage;
my @files = @ARGV       or die $usage;

my $snipper = Search::Tools->snipper(
    query               => $query,
    collapse_whitespace => 1,
    type                => 'loop',
    occur               => 4,
    context             => 12
);

my $hiliter = Search::Tools->hiliter( query => $snipper->query, tty => 1 );

for my $f (@files) {
    my $text = read_file($f);
    my $snip = $snipper->snip($text);
    if ( !$snip ) {
        next;
    }
    print "$f: " . $hiliter->light($snip), $/;
}
