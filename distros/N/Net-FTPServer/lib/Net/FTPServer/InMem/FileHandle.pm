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

=pod

=head1 NAME

Net::FTPServer::InMem::FileHandle - Store files in local memory

=head1 SYNOPSIS

  use Net::FTPServer::InMem::FileHandle;

=head1 METHODS

=cut

package Net::FTPServer::InMem::FileHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp qw(croak confess);
use IO::Scalar;

use Net::FTPServer::FileHandle;
use Net::FTPServer::InMem::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer::FileHandle);

# Return a new file handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;
    my $pathname = shift;
    my $dir_id = shift;
    my $file_id = shift;
    my $content = shift;

    # Create object.
    my $self = Net::FTPServer::FileHandle->new ($ftps, $pathname);

    $self->{fs_dir_id} = $dir_id;
    $self->{fs_file_id} = $file_id;
    $self->{fs_content} = $content;

    return bless $self, $class;
  }

# Return the directory handle for this file.

sub dir
  {
    my $self = shift;

    return Net::FTPServer::InMem::DirHandle->new ($self->{ftps},
						  $self->dirname,
						  $self->{fs_dir_id});
  }

# Open the file handle.

sub open
  {
    my $self = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open file for reading.
      {
	return new IO::Scalar ($self->{fs_content});
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	return new IO::Scalar ($self->{fs_content});
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	return new IO::Scalar ($self->{fs_content});
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

sub status
  {
    my $self = shift;
    my $username = substr $self->{ftps}{user}, 0, 8;

    my $size = length $ { $self->{fs_content} };

    return ( 'f', 0644, 1, $username, "users", $size, 0 );
  }

# Move a file to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    $Net::FTPServer::InMem::DirHandle::files{$self->{fs_file_id}}{dir_id}
      = $dirh->{fs_dir_id};
    $Net::FTPServer::InMem::DirHandle::files{$self->{fs_file_id}}{name}
      = $filename;

    return 0;
  }

# Delete a file.

sub delete
  {
    my $self = shift;

    delete $Net::FTPServer::InMem::DirHandle::files{$self->{fs_file_id}};

    return 0;
  }

1 # So that the require or use succeeds.

__END__

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

C<Net::FTPServer(3)>, C<perl(1)>

=cut
