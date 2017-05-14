#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Select - Base select input element

=cut

=head1 DESCRIPTION

This is a base Select input element.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Select;
use Quizzer::Element;
use strict;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

=head2 show

Select elements are not really visible if there are less than two choices
for them.

=cut

sub visible {
	my $this=shift;
	
	my @choices=$this->question->choices_split;
	return ($#choices > 0);
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
