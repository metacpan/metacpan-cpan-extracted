#!/usr/bin/perl 
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Path::Tiny;
use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate;

my $kate = Syntax::Highlight::Engine::Kate->new(
	language => 'Perl',
);

my $text = path(shift)->slurp;
my @hl = $kate->highlight($text);
print "==\n";
#print Dumper \@hl;
while (@hl) {
	my $string = shift @hl;
	my $type = shift @hl;
	$type ||= 'Normal';
	print "'$string'    '$type'\n";

}
