package Net::FreeDB2::Match;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Error qw (:try);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Match ':all';
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
	my $opt = shift || {};

	defined ($opt->{categ}) && $self->setCateg ($opt->{categ});
	defined ($opt->{discid}) && $self->setDiscid ($opt->{discid});
	defined ($opt->{dtitle}) && $self->setDtitle ($opt->{dtitle});
	return ($self);
}

sub setCateg {
	my $self = shift;

	$self->{Net_FreeDB2_Match}{categ} = shift;
}

sub getCateg {
	my $self = shift;

	return ($self->{Net_FreeDB2_Match}{categ});
}

sub setDiscid {
	my $self = shift;

	$self->{Net_FreeDB2_Match}{discid} = shift;
}

sub getDiscid {
	my $self = shift;

	return ($self->{Net_FreeDB2_Match}{discid});
}

sub setDtitle {
	my $self = shift;

	$self->{Net_FreeDB2_Match}{dtitle} = shift;
}

sub getDtitle {
	my $self = shift;

	return ($self->{Net_FreeDB2_Match}{dtitle});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Match - FreeDB/CDDB query match class

=head1 SYNOPSIS

See L<Net::FreeDB2>.

=head1 DESCRIPTION

The C<Net::FreeDB2::Match> class contains information on FreeDB/CDDB query matches.

Blah blah blah.

=head1 CONSTRUCTOR

=over

=item new ([OPT_HASH_REF])

Creates a new C<Net::FreeDB2::Match> object.

Allowed options for C<OPT_HASH_REF> are:

=over

=item categ

Passed to C<setCateg ()>.

=item discid

Passed to C<setDiscid ()>.

=item dtitle

Passed to C<setDtitle ()>.

=back

=back

=head1 METHODS

=over 

=item setCateg (VALUE)

Set the categ attribute. C<VALUE> is the value.

=item getCateg ()

Returns the categ attribute.

=item setDiscid (VALUE)

Set the discid attribute. C<VALUE> is the value.

=item getDiscid ()

Returns the discid attribute.

=item setDtitle (VALUE)

Set the dtitle attribute. C<VALUE> is the value.

=item getDtitle ()

Returns the dtitle attribute.

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

