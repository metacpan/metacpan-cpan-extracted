package Padre::Wx::Menu::Catalyst;

# Catalyst menu for the main menu bar

use 5.008;
use strict;
use warnings;
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Params::Util '_INSTANCE';
use Padre::Current '_CURRENT';

our $VERSION = '0.51';
our @ISA     = 'Padre::Wx::Menu';

#####################################################################
# Padre::Wx::Menu Methods

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the empty menu as normal
	my $self = $class->SUPER::new(@_);

	# Add additional properties
	$self->{main} = $main;

	# Cache the configuration
	$self->{config} = Padre->ide->config;

	# Menu items
	# TODO: Add the menu items. Sample:
	#	$self->{beginner_check} = $self->add_menu_action(
	#		$self,
	#		'perl.beginner_check',
	#	);
	#
	#	$self->AppendSeparator;

	return $self;
}

sub title {
	my $self = shift;

	return Wx::gettext('&Catalyst');
}

sub refresh {
	my $self = shift;

	# TODO: Change to refresh options for real items

	my $current = _CURRENT(@_);
	my $config  = $current->config;
	my $perl    = !!( _INSTANCE( $current->document, 'Padre::Document::Perl' ) );

	# Disable document-specific entries if we are in a Perl project
	# but not in a Perl document.
	# FIXME: the two commands below crash unless they are defined. Should they
	# ALWAYS be defined or should we leave them like so? (garu)
	$self->{beginner_check}->Enable($perl) if defined $self->{beginner_check};

	# Apply config-driven state
	$self->{autocomplete_brackets}->Check( $config->autocomplete_brackets )
		if defined $self->{autocomplete_brackets};

	return;
}




1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
