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

# $Id: Server.pm,v 1.1 2003/09/28 11:50:45 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::RO::Server - The anonymous read-only FTP server personality

=head1 SYNOPSIS

  ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::RO::Server> is the anonymous read-only FTP server
personality. This personality implements a complete
FTP server with similar functionality to I<wu-ftpd>,
except that it is not possible to write and all logins
must be anonymous.

=head1 METHODS

=over 4

=cut

package Net::FTPServer::RO::Server;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer;
use Net::FTPServer::RO::FileHandle;
use Net::FTPServer::RO::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

# This is called before configuration.

sub pre_configuration_hook
  {
    my $self = shift;

    # Put the personality signature into the version string.
    $self->{version_string} .= " (RO)";
  }

=pod

=item $rv = $self->authentication_hook ($user, $pass, $user_is_anon)

Perform login against C</etc/passwd> or the PAM database.

=cut

sub authentication_hook
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Only allow anonymous users.
    return -1 unless $user_is_anon;

    return 0;
  }

=pod

=item $self->user_login_hook ($user, $user_is_anon)

Hook: Called just after user C<$user> has successfully logged in.

=cut

sub user_login_hook
  {
    my $self = shift;
    my $user = shift;
    my $user_is_anon = shift;

    # For anonymous users, chroot to ftp directory.
    my ($login, $pass, $uid, $gid, $quota, $comment, $gecos, $homedir)
      = getpwnam "ftp"
	or die "no ftp user in password file";

    chroot $homedir or die "cannot chroot: $homedir: $!";

    # We don't allow users to relogin, so completely change to
    # the user specified.
    $self->_drop_privs ($uid, $gid, $login);
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of Net::FTPServer::RO::DirHandle
corresponding to the root directory.

=cut

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::RO::DirHandle ($self);
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 FILES

  /etc/ftpd.conf
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/FileHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/Handle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/RO/Server.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/RO/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/RO/FileHandle.pm

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer(3)>,
L<Net::FTP(3)>,
L<perl(1)>,
RFC 765,
RFC 959,
RFC 1579,
RFC 2389,
RFC 2428,
RFC 2577,
RFC 2640,
Extensions to FTP Internet Draft draft-ietf-ftpext-mlst-NN.txt.

=cut
