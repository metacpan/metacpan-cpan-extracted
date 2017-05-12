# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: IOBlob.pm,v 1.1 2003/09/28 11:50:45 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::DBeg1::IOBlob - The example DB FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::DBeg1::IOBlob;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::DBeg1::IOBlob;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use DBI;
use Carp qw(confess croak);

=item $io = Net::FTPServer::DBeg1::IOBlob ('r', $dbh, $blob_id);

=item $io = Net::FTPServer::DBeg1::IOBlob ('w', $dbh, $blob_id);

Create an IO handle for reading or writing a PostgreSQL blob.

=cut

sub new
  {
    my $class = shift;
    my $mode = shift;
    my $dbh = shift;
    my $blob_id = shift;

    # XXX For some reason PostgreSQL (6.4) fails when you call lo_open
    # the first time. But if you retry a second time it succeeds. Therefore
    # there is this hack. [RWMJ]

    my $blob_fd;

    for (my $retries = 0; !$blob_fd && $retries < 3; ++$retries)
      {
	$blob_fd = $dbh->func ($blob_id,
			       $mode eq 'r' ? $dbh->{pg_INV_READ} : $dbh->{pg_INV_WRITE},
			       'lo_open');
      }

    die "failed to open blob $blob_id: ", $dbh->errstr
      unless $blob_fd;

    my $self = {
		mode => $mode,
		dbh => $dbh,
		blob_id => $blob_id,
		blob_fd => $blob_fd
	       };
    bless $self, $class;

    return $self;
  }

=item $io->getc ();

Read 1 byte from the buffer and return it

=cut

sub getc
  {
    my $self = shift;
    my $buffer;
    if (defined $self->read ($buffer, 1)) {
      return $buffer;
    } else {
      return undef;
    }
  }

=item $io->read ($buffer, $nbytes, [$offset]);

=item $io->sysread ($buffer, $nbytes, [$offset]);

Read C<$nbytes> from the handle and place them in C<$buffer>
at offset C<$offset>.

=cut

sub read
  {
    my $self = shift;
    my $nbytes = $_[1];
    my $offset = $_[2] || 0;

    $self->{dbh}->func ($self->{blob_fd}, substr ($_[0], $offset), $nbytes, 'lo_read');

    return $nbytes;
  }

sub sysread
  {
    my $self = shift;
    my $nbytes = $_[1];
    my $offset = $_[2] || 0;

    $self->{dbh}->func ($self->{blob_fd}, substr ($_[0], $offset), $nbytes, 'lo_read');

    return $nbytes;
  }

=item $io->write ($buffer, $nbytes, [$offset]);

=item $io->syswrite ($buffer, $nbytes, [$offset]);

Write C<$nbytes> to the handle from C<$buffer> offset C<$offset>.

=cut

sub write
  {
    my $self = shift;
    my $nbytes = $_[1];
    my $offset = $_[2] || 0;

    my $buffer = substr $_[0], $offset, $nbytes;

    $self->{dbh}->func ($self->{blob_fd}, $buffer, length $buffer, 'lo_write');

    return $nbytes;
  }

sub syswrite
  {
    my $self = shift;
    my $nbytes = $_[1];
    my $offset = $_[2] || 0;

    my $buffer = substr $_[0], $offset, $nbytes;

    $self->{dbh}->func ($self->{blob_fd}, $buffer, length $buffer, 'lo_write');

    return $nbytes;
  }

=item $io->print ($buffer);

=cut

sub print
  {
    my $self = shift;
    my $buffer = join "", @_;

    return $self->write ($buffer, length $buffer);
  }

=item $io->close;

Close the IO handle.

=cut

sub close
  {
    my $self = shift;

    if ($self->{dbh})
      {
	$self->{dbh}->func ($self->{blob_fd}, 'lo_close');
	delete $self->{dbh};
      }

    return 1;
  }

sub DESTROY
  {
    shift->close;
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer(3)>, L<perl(1)>

=cut
