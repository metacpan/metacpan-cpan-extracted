#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Gtk::Note - Gtk text field

=cut

=head1 DESCRIPTION

This is a Gtk text field in the debconf dialog box.

=cut

package Quizzer::Element::Gtk::Text;
use Gtk;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $self = shift;
#	$self->frontend->newques(
#		$self->question->description, 
#		$self->frontend->maketext(
#			$self->question->extended_description));

	$self->frontend->newques(
		$self->question->description, 
		$self->frontend->maketext(
			$self->question->description));

	return '';
}

1
