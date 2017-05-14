# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2003 Richard W.M. Jones <rich@annexia.org>
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

Net::FTPServer::Proxy::DirHandle - Proxy FTP server

=head1 SYNOPSIS

  use Net::FTPServer::Proxy::DirHandle;

=head1 METHODS

=cut

package Net::FTPServer::Proxy::DirHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp qw(confess croak);
use IO::Scalar;
use File::Temp qw/tempfile/;

use Net::FTPServer::DirHandle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

# Return a new directory handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;		# FTP server object.
    my $pathname = shift || "/"; # (only used in internal calls)

    # Create object.
    my $self = Net::FTPServer::DirHandle->new ($ftps, $pathname);
    bless $self, $class;

    return $self;
  }

# Internal method to get a directory listing. This is complex because it
# involves parsing the return stream from the 'LIST' command, which could
# be in a variety of formats depending on the server.
#
# This function returns an arrayref or undef if it fails.

sub _get_directory_listing
  {
    my $self = shift;
    my $conn = $self->{ftps}{proxy_conn};

    # Change to this directory.
    $conn->cwd ($self->pathname) or return undef;

    # Get a directory listing.
    my $lines = $conn->dir or return undef;

    if ($lines->[0] =~ /^total /) # Probably in Unix format.
      {
	my @lines = @$lines;
	shift @lines;		# Drop "total" line.
	shift @lines;		# Drop "." line.
	shift @lines;		# Drop ".." line.

	@lines = map { _parse_unix_line ($_) } @lines;
	return \@lines;
      }
    elsif ($lines->[0] = ~ /^\d\d-\d\d-\d\d\s/) # Probably Windows IIS.
      {
	my @lines = @$lines;
	@lines = map { _parse_win_iis_line ($_) } @lines;
	my @fake_status = ( 'd', 0755, 1, "Administrator", "Users", 1024, 0 );
	return \@lines;
      }
    else			# Unknown format.
      {
	die "Proxy: unknown format returned from server. You need to change ".
	  "the _get_directory_listing function to be able to handle this ".
	  "format. The server returned:\n\n",
	  (join "\n", @$lines), "\n"
      }
  }

sub _parse_unix_line
  {
    local $_ = shift;

    die "_parse_unix_line: unknown pattern: $_"
      unless (/^(.)(...)(...)(...)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+\s\S+\s\S+)\s(\S+)$/);

    my $mode = $1;
    my $perms = _parse_unix_perms ($2, $3, $4);
    my $nlinks = $5;
    my ($user, $group) = ($6, $7);
    my $size = $8;
    my $mtime = _parse_unix_mtime ($9);
    my $filename = $10;

    [ $filename, [ $mode, $perms, $nlinks, $user, $group, $size, $mtime ]];
  }

sub _parse_unix_perms
  {
    _parse_unix_oct ($_[0]) << 6 |
    _parse_unix_oct ($_[1]) << 3 |
    _parse_unix_oct ($_[2])
  }

sub _parse_unix_oct
  {
    $_[0] =~ /(.)(.)(.)/;
    ($1 eq "r" ? 4 : 0) |
    ($2 eq "w" ? 2 : 0) |
    ($3 eq "x" ? 1 : 0)
  }

sub _parse_unix_mtime
  {
    0; # XXX
  }

sub _parse_win_iis_line
  {
    local $_ = shift;

    if (/^(\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d)(AM|PM)\s+(\d+)\s(\S+)/)
      {
	my $mtime = _parse_win_iis_mtime ($1, $2, $3, $4, $5, $6);
	my $size = $7;
	my $filename = $8;

	[ $filename, [ 'f', 0644, 1, "Administrator", "Users", $size, $mtime ]]
      }
    elsif (/^(\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d)(AM|PM)\s+<DIR>\s+(\S+)/)
      {
	my $mtime = _parse_win_iis_mtime ($1, $2, $3, $4, $5, $6);
	my $filename = $7;

	[ $filename, [ 'd', 0755, 1, "Administrator", "Users", 1024, $mtime ]]
      }
    else
      {
	die "_parse_win_iis_line: unknown pattern: $_"
      }
  }

sub _parse_win_iis_mtime
  {
    0; # XXX
  }

sub _make_handle
  {
    my $dirh = shift;
    my $filename = shift;
    my $type = shift;

    if ($type eq 'd') {
      return new Net::FTPServer::Proxy::DirHandle
	($dirh->{ftps},
	 $dirh->pathname . $filename . "/");
    } else {
      return new Net::FTPServer::Proxy::FileHandle
	($dirh->{ftps},
	 $dirh->pathname . $filename);
    }
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

    # Get a directory listing. We don't know if this file really exists!
    my $listing = $self->_get_directory_listing or return undef;

    # Search for the file/directory by name.
    foreach (@$listing) {
      if ($_->[0] eq $filename) {
	return $self->_make_handle ($_->[0], $_->[1][0]);
      }
    }

    # Not found.
    return undef;
  }

# Get parent of current directory.

sub parent
  {
    my $self = shift;

    return $self if $self->is_root;

    # Get a new directory handle and bless it into the current class.
    my $dirh = $self->SUPER::parent;
    return bless $dirh, ref $self;
  }

sub list
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to regular expression.
    if ($wildcard)
      {
	if ($wildcard ne "*")
	  {
	    $wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
	  }
	else
	  {
	    $wildcard = undef;
	  }
      }

    # Get listing.
    my $listing = $self->_get_directory_listing or return undef;

    # Only wildcard entries.
    my @listing;
    if ($wildcard)
      {
	@listing = grep { $_->[0] =~ /$wildcard/ } @$listing;
      }
    else
      {
	@listing = @$listing;
      }

    # Get a list of filenames, file handles.
    @listing = map { [ $_->[0],
		       _make_handle ($self, $_->[0], $_->[1][0]) ] } @listing;

    return \@listing;
  }

sub list_status
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to regular expression.
    if ($wildcard)
      {
	if ($wildcard ne "*")
	  {
	    $wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
	  }
	else
	  {
	    $wildcard = undef;
	  }
      }

    # Get listing.
    my $listing = $self->_get_directory_listing or return undef;

    # Only wildcard entries.
    my @listing;
    if ($wildcard)
      {
	@listing = grep { $_->[0] =~ /$wildcard/ } @$listing;
      }
    else
      {
	@listing = @$listing;
      }

    # Get a list of filenames, status, add filehandles.
    @listing = map { [ $_->[0],
		       $self->_make_handle ($_->[0], $_->[1][0]),
		       $_->[1]] } @listing;

    return \@listing;
  }

# Return the status of this directory.

sub status
  {
    my $self = shift;

    # XXX FIXME
    return ( 'd', 0755, 1, "-", "-", 0, 0 );
  }

# Move a directory to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    # You can't move the root directory. That would be bad :-)
    return -1 if $self->is_root;

    $self->{ftps}{proxy_conn}->rename ($self->pathname,
				       $dirh->pathname . $filename) ? 0 : -1;
  }

sub delete
  {
    my $self = shift;

    $self->{ftps}{proxy_conn}->rmdir ($self->pathname) ? 0 : -1;
  }

# Create a subdirectory.

sub mkdir
  {
    my $self = shift;
    my $dirname = shift;

    $self->{ftps}{proxy_conn}->cwd ($self->pathname) or return -1;
    $self->{ftps}{proxy_conn}->mkdir ($dirname) ? 0 : -1;
  }

# Open or create a file in this directory.

sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open an existing file for reading.
      {
	# Get the file into a temporary location.
	my ($io, $tmpfile) = tempfile ("ftpsXXXXXX"); # XXX Not secure at all.
	my $r = $self->{ftps}{proxy_conn}->get ($self->pathname . $filename,
						$tmpfile);
	unlink $tmpfile;
	return undef unless $r;
	# Read the file.
	return $io;
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	die "XXX"; # Return an IO handle

	return undef;
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	die "XXX"; # Return an IO handle

	return undef;
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

1 # So that the require or use succeeds.

__END__

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2003 Richard Jones E<lt>rich@annexia.orgE<gt>

=head1 SEE ALSO

C<Net::FTPServer(3)>, C<perl(1)>

=cut
