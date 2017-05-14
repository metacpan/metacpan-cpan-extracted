#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Noninteractive -- Dummy Element

=cut

=head1 DESCRIPTION

This is noninteractive dummy element. When told to display itself, it does
nothing.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Noninteractive;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

=head2 visible

This type of element is not visible.

=cut

sub visible {
	my $this=shift;
	
	return;
}

1
