#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Text::Text - show text to the user

=cut

=head1 DESCRIPTION

This is a peice of text to output to the user.

=cut

package Quizzer::Element::Text::Text;
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
