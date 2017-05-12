package Padre::Wx::Menu::PHP;

# PHP menu functions

# This currently reuses some Perl actions as they do exactly the same.

use 5.008;
use strict;
use warnings;
use List::Util    ();
use File::Spec    ();
use File::HomeDir ();
use Params::Util qw{_INSTANCE};
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Locale   ();
use Padre::Current qw{_CURRENT};

our $VERSION = '0.05';
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

	$self->add_menu_action(
		$self,
		'perl.vertically_align_selected',
	);

	$self->add_menu_action(
		$self,
		'perl.newline_keep_column',
	);

	$self->AppendSeparator;

	$self->{autocomplete_brackets} = $self->add_menu_action(
		$self,
		'perl.autocomplete_brackets',
	);

	return $self;
}

sub title {
	my $self = shift;

	return Wx::gettext('&PHP');
}

sub refresh {
	my $self    = shift;
	my $current = _CURRENT(@_);
	my $config  = $current->config;

	# Apply config-driven state
	$self->{autocomplete_brackets}->Check( $config->autocomplete_brackets );

	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
