package Net::FreeDB2::Site;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Site ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.9 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub new {
	my $class = shift;

	my $self = {};
	bless ($self, (ref($class) || $class));
	return ($self->_initialize (@_));
}

sub _initialize {
	my $self = shift;
	my $opt = shift || {};

	defined ($opt->{site}) && $self->setSite ($opt->{site});
	defined ($opt->{port}) && $self->setPort ($opt->{port});
	defined ($opt->{latitude}) && $self->setLatitude ($opt->{latitude});
	defined ($opt->{longitude}) && $self->setLongitude ($opt->{longitude});
	defined ($opt->{description}) && $self->setDescription ($opt->{description});
	return ($self);
}

sub setSite {
	my $self = shift;

	$self->{Net_FreeDB2_Site}{site} = shift;
}

sub getSite {
	my $self = shift;

	return ($self->{Net_FreeDB2_Site}{site});
}

sub setPort {
	my $self = shift;

	$self->{Net_FreeDB2_Site}{port} = shift;
}

sub getPort {
	my $self = shift;

	return ($self->{Net_FreeDB2_Site}{port});
}

sub setLatitude {
	my $self = shift;

	$self->{Net_FreeDB2_Site}{latitude} = shift;
}

sub getLatitude {
	my $self = shift;

	return ($self->{Net_FreeDB2_Site}{latitude});
}

sub setLongitude {
	my $self = shift;

	$self->{Net_FreeDB2_Site}{longitude} = shift;
}

sub getLongitude {
	my $self = shift;

	return ($self->{Net_FreeDB2_Site}{longitude});
}

sub setDescription {
	my $self = shift;

	$self->{Net_FreeDB2_Site}{description} = shift;
}

sub getDescription {
	my $self = shift;

	return ($self->{Net_FreeDB2_Site}{description});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Site - FreeDB/CDDB query match class

=head1 SYNOPSIS

See L<Net::FreeDB2>.

=head1 DESCRIPTION

The C<Net::FreeDB2::Site> class contains information on FreeDB/CDDB query matches.

=head1 CONSTRUCTOR

=over

=item new ([OPT_HASH_REF])

Creates a new C<Net::FreeDB2::Site> object.

Allowed options for C<OPT_HASH_REF> are:

=over

=item site

Passed to C<setSite ()>.

=item port

Passed to C<setPort ()>.

=item latitude

Passed to C<setLatitude ()>.

=back

=back

=head1 METHODS

=over 

=item setSite (VALUE)

Set the site attribute. C<VALUE> is the value.


=item getSite ()

Returns the site attribute.

=item setPort (VALUE)

Set the port attribute. C<VALUE> is the value.

=item getPort ()

Returns the port attribute.

=item setLatitude (VALUE)

Set the latitude attribute. C<VALUE> is the value.

=item getLatitude ()

Returns the latitude attribute.

=item setLongitude (VALUE)

Set the longitude attribute. C<VALUE> is the value.

=item getLongitude ()

Returns the longitude attribute.

=item setDescription (VALUE)

Set the description attribute. C<VALUE> is the value.

=item getDescription ()

Returns the description attribute.

=back

=head1 SEE ALSO

L<Net::FreeDB2::Response::Query>.

=head1 BUGS

None known.

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<Net::FreeDB2> module hierarchy for Perl by
Vincenzo Zocca.

The Net::FreeDB2 module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The Net::FreeDB2 module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Net::FreeDB2 module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

