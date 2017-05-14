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

Net::FTPServer::Proxy::Server - Proxy FTP server

=head1 SYNOPSIS

  proxy-ftpd.pl [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::Proxy::Server> is a "reverse proxy" FTP server which
just forwards requests through to another FTP server. You can use it
for firewalls, for example.

=head1 CONFIGURATION

C<Net::FTPServer::Proxy::Server> can only proxy to one FTP server for
each virtual host. In other words, it doesn't make remote servers
appear as subdirectories or anything like that, since the FTP
authentication protocol makes this very hard.

You will need to start the FTP server using the C<proxy-ftpd.pl>
script.

To proxy a single server, you need this global configuration file
entry:

 proxy to: hostname [port]

To proxy multiple servers using IP-based virtual hosts, use:

 enable virtual hosts: 1

 <Host proxy.bob.example.com>
   ip: 1.2.3.4
   proxy to: hostname1 [port]
 </Host>

 <Host proxy.bob.example.com>
   ip: 1.2.3.5
   proxy to: hostname2 [port]
 </Host>

=head1 METHODS

=cut

package Net::FTPServer::Proxy::Server;

use strict;

use Net::FTP;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer;
use Net::FTPServer::Proxy::FileHandle;
use Net::FTPServer::Proxy::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

# This is called before configuration.

sub pre_configuration_hook
  {
    my $self = shift;

    $self->{version_string} .= " Net::FTPServer::Proxy/$VERSION";
  }

# Accepted connection. Make a connection to the remote server.

sub post_accept_hook
  {
    my $self = shift;

    # Determine the name of the remote FTP server.
    my $proxy_to = $self->config ("proxy to")
      or die "no 'proxy to' configuration option found in config file!";
    my ($hostname, $port) = split /\s+/, $proxy_to;
    #$port ||= "21";

    # Open a connection to the proxy server using Net::FTP.
    my $conn = new Net::FTP $hostname, Port => $port or die;

    # Save the connection info.
    $self->{proxy_conn} = $conn;
  }

# Perform login against the remote server.

sub authentication_hook
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Try to log in.
    my @args;
    if ($user_is_anon) {
      @args = ("anonymous", "proxy@")
    } else {
      @args = ($user, $pass)
    }

    $self->{proxy_conn}->login (@args) ? 0 : -1;
  }

# Called just after user C<$user> has successfully logged in.

sub user_login_hook
  {
    # Override the default by doing nothing.
  }

# Return an instance of Net::FTPServer::Proxy::DirHandle
# corresponding to the root directory.

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::Proxy::DirHandle ($self);
  }

1 # So that the require or use succeeds.

__END__

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2003 Richard Jones E<lt>rich@annexia.orgE<gt>

=head1 SEE ALSO

C<Net::FTPServer(3)>.

=cut
