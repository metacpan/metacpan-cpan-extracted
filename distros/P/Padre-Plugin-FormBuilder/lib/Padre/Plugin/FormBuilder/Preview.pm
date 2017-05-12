package Padre::Plugin::FormBuilder::Preview;

# This provides a contained for previewing FBP::Panel classes,
# which can not be inherently displayed on their own.

use 5.008;
use strict;
use warnings;
use Padre::Wx             ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.04';
our @ISA     = qw{
	Padre::Wx::Role::Main
	Wx::Dialog
};

sub new {
	my $class  = shift;
	my $parent = shift;
	my $panel  = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("Preview - Panel $panel"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	# Create the panel preview instance
	my $preview = $panel->new($self);

	# Drop it inside a single sizer
	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizer->Add( $preview, 0, Wx::wxALL, 0 );

	$self->SetSizer($sizer);
	$self->Layout;
	$sizer->Fit($self);

	return $self;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
