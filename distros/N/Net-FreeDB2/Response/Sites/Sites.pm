package Net::FreeDB2::Response::Sites;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Error qw (:try);
use base qw (Net::FreeDB2::Response Exporter);

#our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Response::Sites ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

my $CODE_RX = '^\s*(\d{3})\s+';

sub new {
	my $class = shift;

	my $self = {};
	bless ($self, (ref($class) || $class));
	return ($self->_initialize (@_));
}

sub _initialize {
	my $self = shift;
	my $opt = shift || {};

	defined ($opt->{content_ref}) and $self->read ($opt);
	return ($self);
}

sub read {
	my $self = shift;
	my $opt = shift || {};

	# Check if content_ref is specified
	exists ($opt->{content_ref}) || throw Error::Simple ('ERROR: Net::FreeDB2::Response::Sites::read, option \'content_ref\' not defined.');

	# Convert $opt->{content_ref} to @content_ref
	my @content_ref = split (/[\n\r]+/, ${$opt->{content_ref}});

	# Parse first line
	my $line = shift (@content_ref);
	my ($code) = $line =~ /$CODE_RX/;
	defined ($code) || throw Error::Simple ('ERROR: Net::FreeDB2::Response::Sites::read, first line of specified \'content_ref\' does not contain a code.');
	if ($code == 210) {
		my @sites = ();
		while (my $line = shift (@content_ref)) {
			$line eq '.' && last;
			$line =~ /^\s*.\s*$/ && last;
			my @line = split (/\s/, $line, 5);
			use Net::FreeDB2::Site;
			push (@sites, Net::FreeDB2::Site->new ({
				site => $line[0],
				port => $line[1],
				latitude => $line[2],
				longitude => $line[3],
				description => $line[4],
			}));
		}
		$self->setSites (@sites);
		$self->setError (0);
		$self->setResult ('OK');
	} elsif ($code == 401) {
		$self->setSites ();
		$self->setError (0);
		$self->setResult ('No site information available');
	} else {
		throw Error::Simple ("ERROR: Net::FreeDB2::Response::Sites::read, unknown code '$code' returned.");
	}
}

sub setSites {
	my $self = shift;

	@{$self->{Net_FreeDB2_Response_Sites}{sites}} = @_;
}

sub pushSites {
	my $self = shift;

	push (@{$self->{Net_FreeDB2_Response_Sites}{sites}}, @_);
}

sub getSites {
	my $self = shift;

	return (@{$self->{Net_FreeDB2_Response_Sites}{sites}});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Response::Sites - FreeDB/CDDB sites response class

=head1 SYNOPSIS

See L<Net::FreeDB2>.

=head1 DESCRIPTION

The C<Net::FreeDB2::Response::Sites> class contains FreeDB/CDDB response information for sites. It is a subclass of C<Net::FreeDB2::Response>.

=head1 CONSTRUCTOR

=over

=item new ([OPT_HASH_REF])

Creates a new C<Net::FreeDB2::Response::Sites> object. Calls C<read ()> if option C<content_ref> is passed through C<OPT_HASH_REF>.

Options for C<OPT_HASH_REF> may include:

=over

=item content_ref

If defined, passed to C<read ()>.

=back

=back

=head1 METHODS

=over 

=item read (OPT_HASH_REF)

Reads a FreeDB/CDDB response from the C<content_ref> option passed through C<HASH> reference C<OPT_HASH_REF>. Throws an C<Error::Simple> exception option C<content_ref> is not specified or if the first line of C<content_ref> does not contain a valid code.

Options for C<OPT_HASH_REF> may include:

=over

=item content_ref

Mandatory option containing the content replies from the FreeDB/CDDB server.

=back

=item setSites (LIST)

Set the site objects. C<LIST> is a list of C<Net::FreeDB2::Site> objects.

=item pushSites (LIST)

Push site objects onto the site list. C<LIST> is a list of C<Net::FreeDB2::Site> objects.

=item getSites ()

Returns the list of all C<Net::FreeDB2::Site> objects.

=back

=head1 SEE ALSO

L<Net::FreeDB2::Response>.

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

