#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Gtk::Boolean - Gtk check box

=cut

=head1 DESCRIPTION

This is a check box element in the debconf dialog box.

=cut

package Quizzer::Element::Gtk::Boolean;
use Gtk;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

sub show {
	my $self = shift;
	my $vbox = new Gtk::VBox(0,5);

#	my $text = $self->frontend->maketext(
#			$self->question->extended_description);
	my $check = new Gtk::CheckButton($self->question->description);
	my $text = $self->frontend->maketext(
			$self->question->description);

	$check->set_active($self->question->value eq "true" ? 1 : 0)
		if defined $self->question->value;

	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($check, 0,1,0);
	$text->show(); $check->show();

	my $result = $self->frontend->newques(
			$self->question->description, $vbox);

	return $check->active ? "true" : "false";
}

1
