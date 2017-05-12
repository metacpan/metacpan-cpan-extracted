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

# $Id: FileHandle.pm,v 1.1 2003/10/17 14:40:37 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::Proxy::FileHandle - Proxy FTP server

=head1 SYNOPSIS

  use Net::FTPServer::Proxy::FileHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::Proxy::FileHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp qw(croak confess);
use IO::Scalar;
use File::Temp qw/tempfile/;

use Net::FTPServer::FileHandle;
use Net::FTPServer::Proxy::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer::FileHandle);

# Return a new file handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;
    my $pathname = shift;

    # Create object.
    my $self = Net::FTPServer::FileHandle->new ($ftps, $pathname);
    return bless $self, $class;
  }

# Return the directory handle for this file.

sub dir
  {
    my $self = shift;

    return Net::FTPServer::Proxy::DirHandle->new ($self->{ftps},
						  $self->dirname);
  }

# Open the file handle.

sub open
  {
    my $self = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open file for reading.
      {
	# Get the file into a temporary location.
	my ($io, $tmpfile) = tempfile ("ftpsXXXXXX"); # XXX Not secure at all.
	my $r = $self->{ftps}{proxy_conn}->get ($self->pathname,
						$tmpfile);
	unlink $tmpfile;
	return undef unless $r;
	# Read the file.
	return $io;
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	die "XXX";
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	die "XXX";
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

sub status
  {
    my $self = shift;

    # XXX FIXME
    return ( 'f', 0644, 1, "-", "-", 0, 0 );
  }

# Move a file to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    $self->{ftps}{proxy_conn}->rename ($self->pathname,
				       $dirh->pathname . $filename) ? 0 : -1;
  }

# Delete a file.

sub delete
  {
    my $self = shift;

    $self->{ftps}{proxy_conn}->delete ($self->pathname) ? 0 : -1;
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2003 Richard Jones E<lt>rich@annexia.orgE<gt>

=head1 SEE ALSO

L<Net::FTPServer(3)>, L<perl(1)>

=cut
