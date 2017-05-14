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

Net::FTPServer::InMem::Server - Store files in local memory

=head1 SYNOPSIS

  inmem-ftpd.pl [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::InMem::Server> is the example FTP server
personality. This personality implements a simple
FTP server which stores files in local memory. This personality
is used mainly for automatic testing in the test suites (see the
C<t/> directory in the distribution).

=head1 METHODS

=cut

package Net::FTPServer::InMem::Server;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer;
use Net::FTPServer::InMem::FileHandle;
use Net::FTPServer::InMem::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

# Variables.
use vars qw(%users);

$users{rich} = '123456';
$users{rob} = '123456';

# This is called before configuration.

sub pre_configuration_hook
  {
    my $self = shift;

    $self->{version_string} .= " Net::FTPServer::InMem/$VERSION";
  }

# Perform login against the database.

sub authentication_hook
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Allow anonymous access.
    return 0 if $user_is_anon;

    # Verify access against our short list of username/password combinations.
    return 0 if exists $users{$user} && $users{$user} eq $pass;

    # Unsuccessful login.
    return -1;
  }

# Called just after user C<$user> has successfully logged in.

sub user_login_hook
  {
    # Override the default by doing nothing.
  }

#  Return an instance of Net::FTPServer::InMem::DirHandle
# corresponding to the root directory.

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::InMem::DirHandle ($self);
  }

1 # So that the require or use succeeds.

__END__

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

C<Net::FTPServer(3)>.

=cut
