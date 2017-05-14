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

Net::FTPServer::FileHandle - A Net::FTPServer file handle.

=head1 SYNOPSIS

  use Net::FTPServer::FileHandle;

=head1 METHODS

=cut

package Net::FTPServer::FileHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer::Handle;

use Carp qw(confess);

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::Handle);

# This function is intentionally undocumented. It is only meant to
# be called internally.

sub new
  {
    my $class = shift;
    my $ftps = shift;
    my $path = shift;

    my $self = Net::FTPServer::Handle->new ($ftps);
    $self->{_pathname} = $path;

    return bless $self, $class;
  }

=pod

=over 4

=item $filename = $fileh->filename;

Return the filename (last) component.

=cut

sub filename
  {
    my $self = shift;

    if ($self->{_pathname} =~ m,([^/]*)$,)
      {
	return $1;
      }

    confess "incorrect pathname: ", $self->{_pathname};
  }

=pod

=item $dirh = $fileh->dir;

Return the directory which contains this file.

=cut

sub dir
  {
    confess "virtual function";
  }

=pod

=item $fh = $fileh->open (["r"|"w"|"a"]);

Open a file handle (derived from C<IO::Handle>, see
C<IO::Handle(3)>) in either read or write mode.

=cut

sub open
  {
    confess "virtual function";
  }

=item $rv = $fileh->delete;

Delete the current file. If the delete command was
successful, then return 0, else if there was an error return -1.

=cut

sub delete
  {
    confess "virtual function";
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
