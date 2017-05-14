#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Dialog::Password - A password input field in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a password input
field on it.

=cut

package Quizzer::Element::Dialog::Password;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;
	
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);

	my @params=('--passwordbox', $text,
		$lines + $this->frontend->spacer, $columns);

	my $ret=$this->frontend->showdialog(@params);

	# The password isn't passed in, so if nothing is entered,
	# use the default.
	if (! defined $ret || $ret eq '') {
		my $default='';
		$default=$this->question->value
			if defined $this->question->value;
		return $default
	}
	else {
		return $ret;
	}
}

1
