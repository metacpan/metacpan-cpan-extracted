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

Net::FTPServer::DBeg1::FileHandle - The full FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::DBeg1::FileHandle;

=head1 METHODS

=cut

package Net::FTPServer::DBeg1::FileHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp qw(croak confess);

use Net::FTPServer::FileHandle;
use Net::FTPServer::DBeg1::DirHandle;
use Net::FTPServer::DBeg1::IOBlob;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer::FileHandle);

use vars qw($sth1 $sth2 $sth3 $sth4);

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

    return Net::FTPServer::DBeg1::DirHandle->new ($self->{ftps},
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
	return new Net::FTPServer::DBeg1::IOBlob ('r', $self->{ftps}{fs_dbh}, $self->{fs_content});
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	# Remove the existing large object and create a new one.
	my $dbh = $self->{ftps}{fs_dbh};
	my $blob_id = $dbh->func ($dbh->{pg_INV_WRITE}|$dbh->{pg_INV_READ},
				  'lo_creat');

	my $sql = "update files set content = ? where id = ?";
	$sth4 ||= $dbh->prepare ($sql);
	$sth4->execute ($blob_id, int ($self->{fs_file_id}));

	$dbh->func ($self->{fs_content}, 'lo_unlink');
	$self->{fs_content} = $blob_id;

	return new Net::FTPServer::DBeg1::IOBlob ('w', $self->{ftps}{fs_dbh}, $self->{fs_content});
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	return new Net::FTPServer::DBeg1::IOBlob ('w', $self->{ftps}{fs_dbh}, $self->{fs_content});
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

sub status
  {
    my $self = shift;
    my $dbh = $self->{ftps}{fs_dbh};
    my $username = substr $self->{ftps}{user}, 0, 8;

    # Tricky: pull out the size information for this blob.

    # XXX For some reason PostgreSQL (6.4) fails when you call lo_open
    # the first time. But if you retry a second time it succeeds. Therefore
    # there is this hack. [RWMJ]

    my $blob_fd;

    for (my $retries = 0; !$blob_fd && $retries < 3; ++$retries)
      {
	$blob_fd = $dbh->func ($self->{fs_content}, $dbh->{pg_INV_READ},
			       'lo_open');
      }

    die "failed to open blob $self->{fs_content}: ", $dbh->errstr
      unless $blob_fd;

    my $size = $dbh->func ($blob_fd, 0, 2, 'lo_lseek');

    $dbh->func ($blob_fd, 'lo_close');

    return ( 'f', 0644, 1, $username, "users", $size, 0 );
  }

# Move a file to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    my $sql = "update files set dir_id = ?, name = ? where id = ?";
    $sth2 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth2->execute (int ($dirh->{fs_dir_id}), $filename,
		    int ($self->{fs_file_id}));

    return 0;
  }

# Delete a file.

sub delete
  {
    my $self = shift;

    my $sql = "delete from files where id = ?";
    $sth1 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth1->execute (int ($self->{fs_file_id}));

    # Delete the large object.
    $self->{ftps}{fs_dbh}->func ($self->{fs_content}, 'lo_unlink');

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
