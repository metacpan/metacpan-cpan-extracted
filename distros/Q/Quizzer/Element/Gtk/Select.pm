#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Gtk::Select - Gtk select box

=cut

=head1 DESCRIPTION

This is an element on the debconf dialog box that lets the user
pick from a list of valid choices.

=cut


package Quizzer::Element::Gtk::Select;
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

	if (0) {
		$self->radio($vbox);
	} else {
		$self->dropdown($vbox);
	}

	my $result = $self->frontend->newques(
			$self->question->description, $vbox);

	return $self->{newvalue};
}

sub radio {
	my ($self, $vbox) = @_;
	my $radio;

	foreach my $opt ($self->question->choices_split) {
		if ($radio) {
			$radio = new Gtk::RadioButton($opt, $radio);
		} else {
			$radio = new Gtk::RadioButton($opt);
		}
		$radio->signal_connect("toggle",
			sub { 
				$self->{unchanged} = 0;
				$self->{newvalue} = $opt;
			});
		$radio->set_active(1) 
			if ((defined $self->question->value) && ($opt eq $self->question->value));
		$vbox->pack_start($radio, 0,0,0);
		$radio->show();
	}
	return;
}

sub dropdown {
	my ($self, $vbox) = @_;
	my $optmenu = new Gtk::OptionMenu;
	my $menu = new Gtk::Menu;
	my $menuitem;
	my $n = 0;
	my $hist;

	foreach my $opt ($self->question->choices_split) {
		$menuitem = new Gtk::RadioMenuItem($opt, $menuitem);
		$self->{newvalue} = 
			$self->{newvalue} ?
			$self->{newvalue} : $opt;
		$menu->append($menuitem);
		$menuitem->signal_connect("toggled",
			sub { 
				$self->{unchanged} = 0;
				$self->{newvalue} = $opt;
			});
		$menuitem->set_active(1), $hist = $n
			if ((defined $self->question->value) && ($opt eq $self->question->value));
		$menuitem->show();
		$n++;
	}

	$optmenu->set_menu($menu);
	$optmenu->set_history($hist);
	$optmenu->show;
	$vbox->pack_start($optmenu, 0,0,0);
}

1
