#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Dialog::Note - A note in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a note on it.

=cut

package Quizzer::Element::Dialog::Note;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;

	$this->frontend->showtext($this->question->description."\n\n".
		$this->question->extended_description
	);
	return '';
}

1
