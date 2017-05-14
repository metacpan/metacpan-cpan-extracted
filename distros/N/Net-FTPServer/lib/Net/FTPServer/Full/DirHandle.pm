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

Net::FTPServer::Full::DirHandle - The full FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::Full::DirHandle;

=head1 METHODS

=cut

package Net::FTPServer::Full::DirHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;

use IO::Dir;
use Carp qw(confess);

use Net::FTPServer::DirHandle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

=pod

=over 4

=item $handle = $dirh->get ($filename);

Return the file or directory C<$handle> corresponding to
the file C<$filename> in directory C<$dirh>. If there is
no file or subdirectory of that name, then this returns
undef.

=cut

sub get
  {
    my $self = shift;
    my $filename = shift;

    # None of these cases should ever happen.
    confess "no filename" unless defined($filename) && length($filename);
    confess "slash filename" if $filename =~ /\//;
    confess ".. filename"    if $filename eq "..";
    confess ". filename"     if $filename eq ".";

    my $pathname = $self->{_pathname} . $filename;
    stat $pathname;

    if (-d _)
      {
	return Net::FTPServer::Full::DirHandle->new ($self->{ftps}, $pathname."/");
      }

    if (-e _)
      {
	return Net::FTPServer::Full::FileHandle->new ($self->{ftps}, $pathname);
      }

    return undef;
  }

=item $dirh = $dirh->parent;

Return the parent directory of the directory C<$dirh>. If
the directory is already "/", this returns the same directory handle.

=cut

sub parent
  {
    my $self = shift;

    my $parent = $self->SUPER::parent;
    bless $parent, ref $self;
    return $parent;
  }

=pod

=item $ref = $dirh->list ([$wildcard]);

Return a list of the contents of directory C<$dirh>. The list
returned is a reference to an array of pairs:

  [ $filename, $handle ]

The list returned does I<not> include "." or "..".

The list is sorted into alphabetical order automatically.

=cut

sub list
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to a regular expression.
    if ($wildcard)
      {
	$wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
      }

    my $dir = new IO::Dir ($self->{_pathname})
      or return undef;

    my $file;
    my @filenames = ();

    while (defined ($file = $dir->read))
      {
	next if $file eq "." || $file eq "..";
	next if $wildcard && $file !~ /$wildcard/;

	push @filenames, $file;
      }

    $dir->close;

    @filenames = sort @filenames;
    my @array = ();

    foreach $file (@filenames)
      {
        if (my $handle = $self->get($file)) {
          push @array, [ $file, $handle ];
        }
      }

    return \@array;
  }

=pod

=item $ref = $dirh->list_status ([$wildcard]);

Return a list of the contents of directory C<$dirh> and
status information. The list returned is a reference to
an array of triplets:

  [ $filename, $handle, $statusref ]

where $statusref is the tuple returned from the C<status>
method (see L<Net::FTPServer::Handle>).

The list returned does I<not> include "." or "..".

The list is sorted into alphabetical order automatically.

=cut

sub list_status
  {
    my $self = shift;

    my $arrayref = $self->list (@_);
    my $elem;

    foreach $elem (@$arrayref)
      {
	my @status = $elem->[1]->status;
	push @$elem, \@status;
      }

    return $arrayref;
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

    # If the directory has been removed since we created this
    # handle, then $dev will be undefined. Return dummy status
    # information.
    return ("d", 0000, 1, "-", "-", 0, 0) unless defined $dev;

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
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    die if $filename =~ /\//;	# Should never happen.

    my $new_name = $dirh->{_pathname} . $filename;

    rename $self->{_pathname}, $new_name or return -1;

    $self->{_pathname} = $new_name;
    return 0;
  }

=pod

=item $rv = $dirh->delete;

Delete the current directory. If the delete command was
successful, then return 0, else if there was an error return -1.

It is normally only possible to delete a directory if it
is empty.

=cut

sub delete
  {
    my $self = shift;

    # Darwin / Mac OS X cannot delete a directory with a trailing "/", so
    # remove it first (thanks Luis Mun\~oz for fixing this).
    my $path = $self->{_pathname};
    $path =~ s,/+$,, if $path ne "/";
    rmdir $path or return -1;

    return 0;
  }

=item $rv = $dirh->mkdir ($name);

Create a subdirectory called C<$name> within the current directory
C<$dirh>.

=cut

sub mkdir
  {
    my $self = shift;
    my $name = shift;

    die if $name =~ /\//;	# Should never happen.

    mkdir $self->{_pathname} . $name, 0755 or return -1;

    return 0;
  }

=item $file = $dirh->open ($filename, "r"|"w"|"a");

Open or create a file called C<$filename> in the current directory,
opening it for either read, write or append. This function
returns a C<IO::File> handle object.

=cut

sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    die if $filename =~ /\//;	# Should never happen.

    return new IO::File $self->{_pathname} . $filename, $mode;
  }

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

C<Net::FTPServer(3)>, C<perl(1)>

=cut
