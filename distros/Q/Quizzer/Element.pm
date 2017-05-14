#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element - Base input element

=cut

=head1 DESCRIPTION

This is the base object on which many different types of input elements are
built. Each element represents one user interface element in a FrontEnd. 

=cut

=head1 METHODS

=cut

package Quizzer::Element;
use strict;
use Quizzer::Base;
use vars qw(@ISA);
@ISA=qw(Quizzer::Base);

my $VERSION='0.01';

=head2 visible

Returns true if an Element is of a type that is displayed to the user.
This is used to let confmodules know if the elements they have caused to be
displayed are really going to be displayed, or not, so they can avoid loops
and other nastiness.

=cut

sub visible {
	my $this=shift;
	
	return 1;
}

=head2 show

Causes the element to be displayed, allows the user to interact with it to
specify a value, and returns the value they enter (this value is later used to
set the value of the accociated question).

=cut

sub show {}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
