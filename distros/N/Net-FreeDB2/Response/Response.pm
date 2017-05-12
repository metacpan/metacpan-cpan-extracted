package Net::FreeDB2::Response;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;
use Error qw (:try);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Response ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.8.2.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub new {
	my $class = shift;

	my $self = {};
	bless ($self, (ref($class) || $class));
	return ($self->_initialize (@_));
}

sub _initialize {
	my $self = shift;

	return ($self);
}

sub setError {
	my $self = shift;

	$self->{Net_FreeDB2_Response}{error} = int (shift);
}

sub hasError {
	my $self = shift;

	return ($self->{Net_FreeDB2_Response}{error});
}

sub setResult {
	my $self = shift;

	$self->{Net_FreeDB2_Response}{result} = shift;
}

sub getResult {
	my $self = shift;

	return ($self->{Net_FreeDB2_Response}{result});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Response - Abstract class for FreeDB/CDDB responses.

=head1 SYNOPSIS

See L<Net::FreeDB2::Connection>.

=head1 DESCRIPTION

The C<Net::FreeDB2::Response> class contains a default implementation for FreeDB/CDDB response information.

=head1 CONSTRUCTOR

=over

=item new ()

Creates a new C<Net::FreeDB2::Response> object.

=back

=head1 METHODS

=over 

=item setError (VALUE)

Set the error attribute. C<VALUE> is the value.

=item hasError ()

Returns the error attribute.

=item setResult (VALUE)

Set the result string attribute. C<VALUE> is the value.

=item getResult ()

Returns the result string attribute.

=back

=head1 SEE ALSO

L<Net::FreeDB2::Response::Query> and L<Net::FreeDB2::Response::Read>.

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

