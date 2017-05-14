#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Text::Password - password input field

=cut

=head1 DESCRIPTION

This is a password input field, presented to the user using a plain text
interface.

=cut

package Quizzer::Element::Text::Password;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");
	
	my $default='';
	$default=$this->question->value if defined $this->question->value;

	# Prompt for input using the short description.
	my $value=$this->frontend->prompt_password($this->question->description." ", $default);

	# Handle defaults.
	if ($value eq '') {
		$value=$default;
	}
	
	$this->frontend->display("\n");
	return $value;
}

1
