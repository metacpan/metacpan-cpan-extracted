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

# $Id: Handle.pm,v 1.1 2003/09/28 11:50:45 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::Handle - A generic Net::FTPServer file or directory handle.

=head1 SYNOPSIS

  use Net::FTPServer::Handle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::Handle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod

=item $handle = Net::FTPServer::Handle->new ($ftps);

Create a new handle. You would normally call this from
a derived class.

=cut

sub new
  {
    my $class = shift;
    my $ftps = shift;

    my $self = { ftps => $ftps };

    return bless $self, $class;
  }

=pod

=item $rv = $handle->equals ($other_handle);

Decide if two handles refer to the same thing (file or directory).

=cut

sub equals
  {
    my $self = shift;
    my $other = shift;

    return $self->{_pathname} eq $other->{_pathname};
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
    die "virtual function";
  }

=pod

=item $name = $handle->pathname;

Return the full path of this file or directory. The path consists of
all components separated by "/" characters.

If the object is a directory, then the pathname will have
a "/" character at the end.

=cut

sub pathname
  {
    my $self = shift;

    return $self->{_pathname};
  }

=pod

=item $name = $handle->filename;

Return the filename part of the path. If the file is a directory,
then this function returns "".

=cut

sub filename
  {
    my $self = shift;

    $self->{_pathname} =~ m,/([^/]*)$,;
    return $1;
  }

=pod

=item $name = $handle->dirname;

Return the directory name part of the path. The directory name
always has a trailing "/" character.

=cut

sub dirname
  {
    my $self = shift;

    $self->{_pathname} =~ m,^(.*/)([^/]*)$,;
    return $1;
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
    die "virtual function";
  }

=item $rv = $handle->delete;

Delete the current file or directory. If the delete command was
successful, then return 0, else if there was an error return -1.

Different underlying file systems may impose restrictions on
this command: for example, it may not be possible to delete
directories, or only if they are empty.

This is a virtual function which is actually implemented in
one of the subclasses.

=cut

sub delete
  {
    die "virtual function";
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
