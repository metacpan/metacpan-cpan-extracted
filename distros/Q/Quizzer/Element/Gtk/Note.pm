#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Gtk::Note - Gtk text field

=cut

=head1 DESCRIPTION

This is a Gtk text field in the debconf dialog box.

=cut

package Quizzer::Element::Gtk::Note;
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


	my $text = $self->frontend->maketext(
			$self->question->description);

	my $label = new Gtk::Label("");
	
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($label, 0,1,0);
	$text->show(); $label->show();
	$self->frontend->newques($self->question->description, $vbox);
	return '';
}

1
