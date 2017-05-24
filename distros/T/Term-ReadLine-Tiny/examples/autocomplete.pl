#!/usr/bin/env perl

use strict;
use warnings;
use Term::ReadLine::Tiny;

sub common_stem
{
	my $stem = '';
	my $i = 0;
	while () {
		last if $i > length $_[0];		
		my $maybe_stem = substr($_[0], 0, $i);
		my @orphans    = grep !/^\Q$maybe_stem/i, @_;
		last if @orphans;
		$stem = $maybe_stem;
		++$i;
	}
	return $stem;
}

my $term = Term::ReadLine::Tiny->new;

my @colours = map { chomp; $_ } <DATA>;
$term->autocomplete(sub {
	my ($term, $line) = @_;
	my @candidates = grep /^\Q$line/i, @colours;
	
	return if @candidates == 0;
	return $candidates[0] if @candidates == 1;
	
	print { $term->OUT } "\nAmbiguous: @candidates\n";
	return common_stem(@candidates);
});

my @chosen;
print { $term->OUT } "Choose some colours.\n";
print { $term->OUT } "Enter a blank line when you are finished.\n";
while (defined(my $c = $term->readline)) {
	last if $c eq '';
	push @chosen, $c;
	print { $term->OUT } "Got it!\n";
}
print { $term->OUT } "You chose: @chosen.\n";
exit;

__DATA__
Red
Orange
Yellow
Green
Blue
Indigo
Violet
Black
White
Pink
Purple
Gold
Silver
Grey
Magenta
Cyan
Blackish
