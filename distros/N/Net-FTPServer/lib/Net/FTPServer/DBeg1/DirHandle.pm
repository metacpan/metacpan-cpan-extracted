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

# $Id: DirHandle.pm,v 1.1 2003/09/28 11:50:45 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::DBeg1::DirHandle - The example DB FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::DBeg1::DirHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::DBeg1::DirHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use DBI;
use Carp qw(confess croak);

use Net::FTPServer::DirHandle;
use Net::FTPServer::DBeg1::IOBlob;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

# Cached statement handles.
use vars qw($sth1 $sth2 $sth3 $sth4 $sth5 $sth6 $sth7 $sth8 $sth9 $sth10 $sth11 $sth12 $sth13 $sth14 $sth15 $sth16 $sth17 $sth18 $sth19 $sth20);

# Return a new directory handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;		# FTP server object.
    my $pathname = shift || "/"; # (only used in internal calls)
    my $dir_id = shift;		# (only used in internal calls)

    # Create object.
    my $self = Net::FTPServer::DirHandle->new ($ftps, $pathname);
    bless $self, $class;

    if ($dir_id)
      {
	$self->{fs_dir_id} = $dir_id;
      }
    else
      {
	# Find the root directory ID.
	my $sql = "select id from directories where parent_id is null";
	$sth6 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth6->execute;

	my $row = $sth6->fetch
	  or die "no root directory in database (has the database been populated?): $!";

	$self->{fs_dir_id} = $row->[0];
      }

    return $self;
  }

# Return a subdirectory handle or a file handle within this directory.

sub get
  {
    my $self = shift;
    my $filename = shift;

    # None of these cases should ever happen.
    confess "no filename" unless defined($filename) && length($filename);
    confess "slash filename" if $filename =~ /\//;
    confess ".. filename"    if $filename eq "..";
    confess ". filename"     if $filename eq ".";

    # Search for the file first, since files are more common than dirs.
    my $sql = "select id, content from files where dir_id = ? and name = ?";
    $sth1 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth1->execute (int ($self->{fs_dir_id}), $filename);

    my $row = $sth1->fetch;

    if ($row)
      {
	# Found a file.
	return new Net::FTPServer::DBeg1::FileHandle ($self->{ftps},
						      $self->pathname . $filename,
						      $self->{fs_dir_id},
						      $row->[0], $row->[1],
						      $row->[2]);
      }

    # Search for a directory.
    $sql = "select id from directories where parent_id = ? and name = ?";
    $sth2 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth2->execute (int ($self->{fs_dir_id}), $filename);

    $row = $sth2->fetch;

    if ($row)
      {
	# Found a directory.
	return new Net::FTPServer::DBeg1::DirHandle ($self->{ftps},
						     $self->pathname . $filename . "/",
						     $row->[0]);
      }

    # Not found.
    return undef;
  }

# Get parent of current directory.

sub parent
  {
    my $self = shift;

    return $self if $self->is_root;

    # Get a new directory handle.
    my $dirh = $self->SUPER::parent;

    # Find directory ID of the parent directory.
    my $sql = "select parent_id from directories where id = ?";
    $sth3 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth3->execute (int ($self->{fs_dir_id}));

    my $row = $sth3->fetch
      or die "directory ID ", $self->{fs_dir_id}, " missing";

    $dirh->{fs_dir_id} = $row->[0];

    return bless $dirh, ref $self;
  }

sub list
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard into a SQL LIKE pattern.
    if ($wildcard)
      {
        if ($wildcard ne "*")
          {
	    $wildcard = $self->{ftps}->wildcard_to_sql_like ($wildcard);
          }
        else
          {
            # If wildcard is "*" then it defaults to undefined (for speed).
            $wildcard = undef;
          }
      }

    # Get subdirectories.
    my ($sql, $sth);
    if ($wildcard)
      {
	$sql = "select id, name from directories
                 where parent_id = ? and name like ?";
	$sth15 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth15->execute (int ($self->{fs_dir_id}), $wildcard);
	$sth = $sth15;
      }
    else
      {
	$sql = "select id, name from directories where parent_id = ?";
	$sth4 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth4->execute (int ($self->{fs_dir_id}));
	$sth = $sth4;
      }

    my @result = ();
    my $username = substr $self->{ftps}{user}, 0, 8;

    while (my $row = $sth->fetch)
      {
	my $dirh
	  = new Net::FTPServer::DBeg1::DirHandle ($self->{ftps},
						  $self->pathname . $row->[1] . "/",
						  $row->[0]);

	push @result, [ $row->[1], $dirh ];
      }

    # Get files.
    if ($wildcard)
      {
	$sql = "select id, name, content from files
                 where dir_id = ? and name like ?";
	$sth16 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth16->execute (int ($self->{fs_dir_id}), $wildcard);
	$sth = $sth16;
      }
    else
      {
	$sql = "select id, name, content from files where dir_id = ?";
	$sth5 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth5->execute (int ($self->{fs_dir_id}));
	$sth = $sth5;
      }

    while (my $row = $sth->fetch)
      {
	my $fileh
	  = new Net::FTPServer::DBeg1::FileHandle ($self->{ftps},
						   $self->pathname . $row->[1],
						   $self->{fs_dir_id},
						   $row->[0],
						   $row->[2]);

	push @result, [ $row->[1], $fileh ];
      }

    return \@result;
  }

sub list_status
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard into a SQL LIKE pattern.
    if ($wildcard)
      {
        if ($wildcard ne "*")
          {
	    $wildcard = $self->{ftps}->wildcard_to_sql_like ($wildcard);
          }
        else
          {
            # If wildcard is "*" then it defaults to undefined (for speed).
            $wildcard = undef;
          }
      }

    # Get subdirectories.
    my ($sql, $sth);
    if ($wildcard)
      {
	$sql = "select id, name from directories
                 where parent_id = ? and name like ?";
	$sth18 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth18->execute (int ($self->{fs_dir_id}), $wildcard);
	$sth = $sth18;
      }
    else
      {
	$sql = "select id, name from directories where parent_id = ?";
	$sth17 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth17->execute (int ($self->{fs_dir_id}));
	$sth = $sth17;
      }

    my @result = ();
    my $username = substr $self->{ftps}{user}, 0, 8;

    while (my $row = $sth->fetch)
      {
	my $dirh
	  = new Net::FTPServer::DBeg1::DirHandle ($self->{ftps},
						  $self->pathname . $row->[1] . "/",
						  $row->[0]);

	my @status = $dirh->status;
	push @result, [ $row->[1], $dirh, \@status ];
      }

    # Get files.
    if ($wildcard)
      {
	$sql = "select id, name, content from files
                 where dir_id = ? and name like ?";
	$sth20 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth20->execute (int ($self->{fs_dir_id}), $wildcard);
	$sth = $sth20;
      }
    else
      {
	$sql = "select id, name, content from files where dir_id = ?";
	$sth19 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth19->execute (int ($self->{fs_dir_id}));
	$sth = $sth19;
      }

    while (my $row = $sth->fetch)
      {
	my $fileh
	  = new Net::FTPServer::DBeg1::FileHandle ($self->{ftps},
						   $self->pathname . $row->[1],
						   $self->{fs_dir_id},
						   $row->[0],
						   $row->[2]);

	my @status = $fileh->status;
	push @result, [ $row->[1], $fileh, \@status ];
      }

    return \@result;
  }

# Return the status of this directory.

sub status
  {
    my $self = shift;
    my $username = substr $self->{ftps}{user}, 0, 8;

    return ( 'd', 0755, 1, $username, "users", 1024, 0 );
  }

# Move a directory to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    # You can't move the root directory. That would be bad :-)
    return -1 if $self->is_root;

    my $sql = "update directories set parent_id = ?, name = ? where id = ?";
    $sth12 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth12->execute (int ($dirh->{fs_dir_id}), $filename,
		     int ($self->{fs_dir_id}));

    return 0;
  }

# We should only be able to delete a directory if the directory
# is empty. Postgres >= 6.5 can check this using referential
# constraints. However, I'm using Postgres 6.4, so instead I have
# to check the constraints by hand before allowing the delete.

sub delete
  {
    my $self = shift;

    # Check referential constraints.
    my $sql = "select count(id) from files where dir_id = ?";
    $sth7 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth7->execute (int ($self->{fs_dir_id}));

    my $row = $sth7->fetch or die "no rows returned from count";

    my $nr_files = $row->[0];

    $sql = "select count(id) from directories where parent_id = ?";
    $sth8 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth8->execute (int ($self->{fs_dir_id}));

    $row = $sth8->fetch or die "no rows returned from count";

    my $nr_dirs = $row->[0];

    return -1 if $nr_files > 0 || $nr_dirs > 0;

    # Delete the directory.
    $sql = "delete from directories where id = ?";
    $sth9 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth9->execute (int ($self->{fs_dir_id}));

    return 0;
  }

# Create a subdirectory.

sub mkdir
  {
    my $self = shift;
    my $dirname = shift;

    my $sql = "insert into directories (parent_id, name)
                                values (?, ?)";
    $sth10 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
    $sth10->execute (int ($self->{fs_dir_id}), $dirname);

    return 0;
  }

# Open or create a file in this directory.

sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open an existing file for reading.
      {
	my $sql = "select content from files where dir_id = ? and name = ?";
	$sth11 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth11->execute (int ($self->{fs_dir_id}), $filename);

	my $row = $sth11->fetch or return undef;

	return new Net::FTPServer::DBeg1::IOBlob ('r', $self->{ftps}{fs_dbh}, $row->[0]);
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	my $dbh = $self->{ftps}{fs_dbh};
	my $blob_id = $dbh->func ($dbh->{pg_INV_WRITE}|$dbh->{pg_INV_READ},
				  'lo_creat');

	# Insert it into the database.
	my $sql = "insert into files (name, dir_id, content) values (?, ?, ?)";
	$sth14 ||= $dbh->prepare ($sql);
	$sth14->execute ($filename, int ($self->{fs_dir_id}), $blob_id);

	return new Net::FTPServer::DBeg1::IOBlob ('w', $self->{ftps}{fs_dbh}, $blob_id);
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	my $sql = "select content from files where dir_id = ? and name = ?";
	$sth13 ||= $self->{ftps}{fs_dbh}->prepare ($sql);
	$sth13->execute (int ($self->{fs_dir_id}), $filename);

	my $row = $sth13->fetch or return undef;

	return new Net::FTPServer::DBeg1::IOBlob ('w', $self->{ftps}{fs_dbh}, $row->[0]);
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
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
