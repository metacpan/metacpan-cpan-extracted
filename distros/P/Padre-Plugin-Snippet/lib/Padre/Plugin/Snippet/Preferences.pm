package Padre::Plugin::Snippet::Preferences;

use 5.008;
use Padre::Plugin::Snippet::FBP::Preferences ();

our $VERSION = '0.01';
our @ISA     = qw{
	Padre::Plugin::Snippet::FBP::Preferences
};

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent);
	$self->CenterOnParent;

	return $self;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
