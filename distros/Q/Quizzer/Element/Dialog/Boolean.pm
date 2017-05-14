#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Dialog::Boolean - Yes/No dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with Yes and No buttons
on it.

=cut

package Quizzer::Element::Dialog::Boolean;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $this=shift;

	# Note 1 is passed in, because we can squeeze on one more line
	# in a yesno dialog than in other types.
	my @params=('--yesno', $this->frontend->makeprompt($this->question, 1));
	if (defined $this->question->value && $this->question->value eq 'false') {
		# Put it at the start of the option list,
		# where dialog likes it.
		unshift @params, '--defaultno';
	}

	my ($ret, $value)=$this->frontend->showdialog(@params);
	return $ret eq 0 ? 'true' : 'false';
}

1
