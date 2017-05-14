#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Text::Note - A note to the user

=cut

=head1 DESCRIPTION

This is a note to the user, presented using a plain text interface.

=cut

package Quizzer::Element::Text::Note;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n".
		$this->question->extended_description."\n");

	return '';
}

1
