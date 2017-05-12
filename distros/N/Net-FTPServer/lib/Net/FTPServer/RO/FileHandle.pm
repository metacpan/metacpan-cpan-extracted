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

# $Id: FileHandle.pm,v 1.2 2004/11/10 14:24:57 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::RO::FileHandle - The anonymous, read-only FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::RO::FileHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::RO::FileHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer::FileHandle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::FileHandle);

=pod

=item $dirh = $fileh->dir;

Return the directory which contains this file.

=cut

sub dir
  {
    my $self = shift;

    my $dirname = $self->{_pathname};
    $dirname =~ s,[^/]+$,,;

    return Net::FTPServer::RO::DirHandle->new ($self->{ftps}, $dirname);
  }

=pod

=item $fh = $fileh->open (["r"|"w"|"a"]);

Open a file handle (derived from C<IO::Handle>, see
L<IO::Handle(3)>) in either read or write mode.

=cut

sub open
  {
    my $self = shift;
    my $mode = shift;

    return undef unless $mode eq "r";

    return new IO::File $self->{_pathname}, $mode;
  }

=pod

=item ($mode, $perms, $nlink, $user, $group, $size, $time) = $handle->status;

Return the file or directory status. The fields returned are:

  $mode     Mode        'd' = directory,
                        'f' = file,
                        and others as with
                        the find(1) -type option.
  $perms    Permissions Permissions in normal octal numeric format.
  $nlink    Link count
  $user     Username    In printable format.
  $group    Group name  In printable format.
  $size     Size        File size in bytes.
  $time     Time        Time (usually mtime) in Unix time_t format.

In derived classes, some of this status information may well be
synthesized, since virtual filesystems will often not contain
information in a Unix-like format.

=cut

sub status
  {
    my $self = shift;

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
	$atime, $mtime, $ctime, $blksize, $blocks)
      = lstat $self->{_pathname};

    # If the file has been removed since we created this
    # handle, then $dev will be undefined. Return dummy status
    # information.
    return ("f", 0000, 1, "-", "-", 0, 0) unless defined $dev;

    # Generate printable user/group.
    my $user = getpwuid ($uid) || "-";
    my $group = getgrgid ($gid) || "-";

    # Permissions from mode.
    my $perms = $mode & 0777;

    # Work out the mode using special "_" operator which causes Perl
    # to use the result of the previous stat call.
    $mode
      = (-f _ ? 'f' :
	 (-d _ ? 'd' :
	  (-l _ ? 'l' :
	   (-p _ ? 'p' :
	    (-S _ ? 's' :
	     (-b _ ? 'b' :
	      (-c _ ? 'c' : '?')))))));

    return ($mode, $perms, $nlink, $user, $group, $size, $mtime);
  }

=pod

=item $rv = $handle->move ($dirh, $filename);

Move the current file (or directory) into directory C<$dirh> and
call it C<$filename>. If the operation is successful, return 0,
else return -1.

Underlying filesystems may impose limitations on moves: for example,
it may not be possible to move a directory; it may not be possible
to move a file to another directory; it may not be possible to
move a file across filesystems.

=cut

sub move
  {
    return -1;			# Not permitted in read-only server.
  }

=pod

=item $rv = $fileh->delete;

Delete the current file. If the delete command was
successful, then return 0, else if there was an error return -1.

=cut

sub delete
  {
    return -1;			# Not permitted in read-only server.
  }

=item $link = $fileh->readlink;

If the current file is really a symbolic link, read the contents
of the link and return it.

=cut

sub readlink
  {
    my $self = shift;

    return readlink $self->{_pathname};
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
