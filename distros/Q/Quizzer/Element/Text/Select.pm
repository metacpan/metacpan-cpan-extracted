#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Text::Select - select from a list of values

=cut

=head1 DESCRIPTION

This lets the user pick from a number of values, using a plain text interface.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Text::Select;
use strict;
use Quizzer::Element::Select;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Select);

my $VERSION='0.01';

=head2 pickabbrevs

This method picks what abbreviations the user should type to select items from
a list. When possible, it uses the first letter of a list item as the
abbreviation. If two items share a letter, it finds and uses an unused letter
instead. If it uses up all letters of the alphabet, it uses numbers for the
rest of the abbreviations. It allows you to mark some items as important; 
it will allocate the best hotkeys to them that it can.

Pass in reference to an array listing the important items, followed by 
an array of all the items. A hash will be returned, with the items as keys
and the abbreviations as values.

=cut

sub pickabbrevs {
	my $this=shift;
	my @important=@{(shift)};
	my @items=@_;

	my %alphabet=map { chr(97 + $_) => 1 } 0..25;
	my %abbrevs;
	
	# First pass -- find hotkeys that match the first character of
	# the item.
	my $count=0;
	foreach my $item (@important, @items) {
		if (! $abbrevs{$item} && $item =~ m/^([a-z])/i && $alphabet{lc $1}) {
			$abbrevs{$item}=lc $1;
			$alphabet{lc $1}='';
			$count++;
		}
	}
	
	return %abbrevs if $count == @items; # Done; short circuit.
	
	# Second pass -- assign hotkeys to items that don't yet have one,
	# from what's left of the alphabet. If the alphabet is exhausted,
	# start counting up from 1.
	my @alphabits=grep { $alphabet{$_} } keys %alphabet;
	my $counter=1;
	foreach my $item (@items) {
		$abbrevs{$item} = (shift @alphabits || $counter++)
			unless $abbrevs{$item};
	}

	return %abbrevs;
}

=head2 expandabbrev

Pass this method what the user entered, followed by the hash returned by
pickabbrevs. It will expand the abbreviation they entered and return the
choice that corresponds to it. If they entered an invalid abbreviation,
it returns false.

=cut

sub expandabbrev {
	my $this=shift;
	my $abbrev=lc shift;
	my %values=reverse @_;

	return $values{$abbrev} if exists $values{$abbrev};
	return '';
}

sub show {
	my $this=shift;

	my @choices=$this->question->choices_split;
	my $default=$this->question->value || '';
	
	# Make sure the default is in the set of choices, else ignore it.
	if (! grep { $_ eq $default } @choices) {
		$default='';
	}
	
	# Come up with the set of abbreviations to use.
	my @important;
	push @important, $default if $default ne '';
	my %abbrevs=$this->pickabbrevs(\@important, @choices);

	# Print out the question.
	$this->frontend->display($this->question->extended_description."\n");
	foreach (@choices) {
		$this->frontend->display_nowrap("\t$abbrevs{$_}. $_");
	}
	$this->frontend->display("\n");

	# Prompt until a valid answer is entered.
	my $value;
	while (1) {
		$value=$this->expandabbrev($this->frontend->prompt(
						$this->question->description,
						$default ne '' ? $abbrevs{$default} : ''),
					   %abbrevs);
		last if $value ne '';
	}	
	$this->frontend->display("\n");
	return $value;
}

1
