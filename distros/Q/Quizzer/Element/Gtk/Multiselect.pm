#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Gtk::Multiselect - Gtk select box

=cut

=head1 DESCRIPTION

This is an element on the debconf dialog box that lets the user
pick from a list of valid choices.

=cut


package Quizzer::Element::Gtk::Multiselect;
use Gtk;
use strict;
use Quizzer::Element::Select;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Select);

my $VERSION='0.01';

sub show {
	my $self = shift;
	
	my $vbox = new Gtk::VBox(0,5);
#	my $text = $self->frontend->maketext(
#			$self->question->extended_description);

	my $text = $self->frontend->maketext(
			$self->question->description);


	$vbox->pack_start($text, 1,1,0);
	$text->show();

	$self->{unchanged} = 1;
	$self->{newvalue} = undef;

	$self->checkbox($vbox);

	my $result = $self->frontend->newques(
			$self->question->description, $vbox);

	return $self->{newvalue};
}

sub checkbox {

	my ($self, $vbox) = @_;
	my $checkbox;

	foreach my $opt ($self->question->choices_split) {

		$checkbox = new Gtk::CheckButton($opt);

		$checkbox->signal_connect("toggled",
			sub { 
				$self->{unchanged} = 0;

				if ($self->{newvalue}) {
					$self->{newvalue} .= ", $opt";
				} else {
					$self->{newvalue} = "$opt";
				}
			});

		$checkbox->set_active(1)

		if ((defined $self->question->value) && ($opt eq $self->question->value));

		$vbox->pack_start($checkbox, 0,0,0);
		$checkbox->show();
	}
	return;
}

1
