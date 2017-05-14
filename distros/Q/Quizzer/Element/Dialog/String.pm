#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Dialog::String - A text input field in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a text input
field on it.

=cut

package Quizzer::Element::Dialog::String;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;

	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);	

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	my @params=('--inputbox', $text, 
		$lines + $this->frontend->spacer, 
		$columns, $default);

	return $this->frontend->showdialog(@params);
}

1
