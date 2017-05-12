package Siebel::Srvrmgr::Log::Enterprise::Archive;

=pod

=head1 NAME

Siebel::Srvrmgr::Log::Enterprise::Archive - a Moose Role for Enterprise log file data archiving

=head1 SYNOPSIS

    package MyArchive;
    
    with 'Siebel::Srvrmgr::Log::Enterprise::Archive';
    
    sub add {
    
        # code implementation
    
    }
    
    # keep adding other required methods

=head1 DESCRIPTION

This module is a L<Moose::Role>, basically definying a interface to acommodate the persistence of data read from a Siebel Enterprise log file
with L<Siebel::Srvrmgr::OS::UNIX>.

Being a role, it doesn't provide much implementation: how the persistance of the will be done is left to the programmer. Since the data itself will
be a hash reference, there are a lot of options available out there.

=cut

use warnings;
use strict;
use Moose::Role;
use Scalar::Util::Numeric qw(isint);
use Carp;
our $VERSION = '0.29'; # VERSION

=head1 ATTRIBUTES

=head2 archive

A hash reference. It is a required attribute during object creation.

It is also a read-only attribute.

The keys on the hash reference will be PIDs, the values the component alias of the Siebel Enterprise log file, when applicable.

=cut

has 'archive' => (
    is     => 'rw',
    isa    => 'HashRef',
    reader => 'get_archive',
    writer => 'set_archive'
);

=head1 METHODS

=head2 Required methods

The required methods to be implemented are:

=over

=item *

add: adds a new key/value item to the archive. Expects as parameters a the PID and a string to be used as value.

=item *

remove: removes a key/value item from the archive. Expects as parameter the PID.

=item *

get_set: returns a L<Set::Tiny> object created with the keys (PIDs) available in the archive.

=item *

get_alias: returns the stored component alias or undef if the PID does not exists. Expects as parameter a PID.

=item *

reset: remove all key/values from the archive.

=item *

has_digest: returns true if a hash computed from the Siebel Enteprise log file header is available, false otherwise.

=item *

get_digest: returns the hash computed from the Siebel Enteprise log file header.

=item *

_set_digest: sets the hash calculated from the Siebel Enterprise log file header. "Private" method.

=item *

validate_archive: validates if the archive is still valid. Receives as parameter the header of the Siebel Enterprise log, creates a hash for it and compares with the
hash already stored.

=back

A hash of the Siebel Enterprise log file must be taken to allow identification of the bounce of the Siebel Server (and the need to reset the archive). On the other hand, 
this role does not implement any hash, this is left to the programmer. A example of hash would be L<Digest::MD5>.

=cut

requires(
    qw(add remove get_set get_alias reset has_digest get_digest _set_digest validate_archive)
);

=head2 new

The constructor expects a hash reference with the archive as the required attribute.

Implementations of this role also B<will need> to implement a BUILD method and invoke the "private" method C<_init_last_line> without any parameter. This is required
to set the control of lines read from the Siebel Enterprise log file.

=cut

sub _init_last_line {

    my $self    = shift;
    my $archive = $self->get_archive();

    confess "archive method is undefined or is invalid"
      unless ( ( defined($archive) ) and ( ref($archive) eq 'HASH' ) );

    $archive->{LAST_LINE} = 0 unless ( exists( $archive->{LAST_LINE} ) );

}

=head2 set_last_line

Sets the last line read from the Siebel Enterprise log file. Expects as parameter a integer.

=cut

sub set_last_line {

    my $self  = shift;
    my $value = shift;

    confess "value parameter must be defined" unless ( defined($value) );
    confess "invalid value received as parameter: '$value'"
      unless ( isint($value) == 1 );

    my $archive = $self->get_archive();

    $archive->{LAST_LINE} = $value;
}

=head2 get_last_line

Returns a integer representing the last line read from the Siebel Enterprise log file.

=cut

sub get_last_line {

    my $self = shift;

    return $self->get_archive()->{LAST_LINE};

}

=head1 SEE ALSO

=over

=item *

L<Moose::Role>

=item *

L<Siebel::Srvrmgr::OS::UNIX>

=item *

L<Scalar::Util::Numeric>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

