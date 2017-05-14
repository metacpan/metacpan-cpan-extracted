#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Text::Multiselect - select multiple items

=cut

=head1 DESCRIPTION

This lets the user select multiple items from a list of values, using a plain
text interface. (This is hard to do in plain text, and the UI I have made isn't
very intuitive.)

=cut

package Quizzer::Element::Text::Multiselect;
use strict;
use Quizzer::Element::Text::Select;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Text::Select);

my $VERSION='0.01';

sub show {
	my $this=shift;

	my @pdefault;
	my @selected;
	my $none_of_the_above="none of the above";

	my @choices=$this->question->choices_split;
	my %value=map { $_ => 1 } $this->question->value_split;
	my @important=keys %value;
	if ($this->frontend->promptdefault && $this->question->value ne '') {
		push @choices, $none_of_the_above;
		push @important, $none_of_the_above;
	}
	my %abbrevs=$this->pickabbrevs(\@important, @choices);
	
	# Print out the question. At the same time, build up
	# the list of items selected by default.
	$this->frontend->display($this->question->extended_description."\n");
	foreach (@choices) {
		$this->frontend->display_nowrap("\t[$abbrevs{$_}] $_");
		push @pdefault, $abbrevs{$_} if $value{$_};
	}
	$this->frontend->display("\n(Type in the letters of the items you want to select, separated by spaces.)\n");

	# Prompt until a valid answer is entered.
	my $value;
	while (1) {
		$_=$this->frontend->prompt($this->question->description,
		 	join(" ",@pdefault));

		# Split up what they entered. They can separate items
		# with whitespace, commas, etc.
		@selected=split(/[^A-Za-z0-9]*/, $_);

		# Expand the abbreviations in what they entered. If they
		# ented something that does not expand, loop.
		@selected=map { $this->expandabbrev($_, %abbrevs) } @selected;

		# Test to make sure everything they entered expanded ok.
		next if grep { $_ eq '' } @selected;

		# Make sure that they didn't select "none of the above"
		# along with some other item. That's undefined, so don't
		# accept it.
		if ($#selected > 0) {
			map { next if $_ eq $none_of_the_above } @selected;
		}
		
		last;
	}


	if (defined $selected[0] && $selected[0] eq $none_of_the_above) {
		$value='';
	}
	else {
		# Make sure that no item was entered twice. If so, remove
		# the duplicate.
		my %selected=map { $_ => 1 } @selected;
		$value=join(', ', sort keys %selected);
	}

	$this->frontend->display("\n");
	return $value;
}

1
