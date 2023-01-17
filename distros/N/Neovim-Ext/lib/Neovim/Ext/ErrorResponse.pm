package Neovim::Ext::ErrorResponse;
$Neovim::Ext::ErrorResponse::VERSION = '0.06';
use strict;
use warnings;


sub new
{
	my ($this, $msg) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		msg => $msg
	};

	return bless $self, $class;
}

1;

=head1 NAME

Neovim::Ext::ErrorResponse - ErrorResponse exception class

=head1 VERSION

version 0.06

=head1 FUNCTIONS

=head2 new( $msg )

Create a new instance.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
