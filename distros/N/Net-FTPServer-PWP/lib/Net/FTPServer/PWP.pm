
use vars qw($VERSION);

$VERSION = '1.21';

1;

__END__

=pod

=head1 NAME

Net::FTPServer::PWP - The FTP server for PWP (personal web pages) service.

=head1 SYNOPSIS

  ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::PWP> is a L<Net::FTPServer> server personality. This
personality implements a complete FTP server with special
features to support an environment we call PWP.

What we call PWP (Personal Web Pages) is a particular scenario where
possibly millions of users share a pool of "stateless" FTP servers
that access filesystems where their personal web pages are stored. In
this scenario, it is impractical to assign a unique user-id to each
user for permission control. Also, the authentication depends on an
external AAA server, which in our case is a RADIUS server.

We based the implementation in the L<Net::FTPServer> framework, which
provides complete FTP server functionality. Our architecture is
discussed later.

The features provided include:

=over

=item *

Directory quotas

=item *

Authentication using the RADIUS protocol

=item *

Configurable root directory, supplied through the RADIUS server

=back

=head2 RADIUS Authentication

We chose to implement a direct RADIUS authentication rather than using
a service such as PAM, because we wanted to get back from the RADIUS
server some of the operational parameters, such as the user quota and
the home directory.

For this, we use Vendor-Specific Attributes with an arbitrarily chosen
vendor identifier of 582. Of course, you can change this id in the
dictionaries involved and the config file, and nobody should complain.

Please take a look at the pwp-dictionary file that was distributed
along this module, in order to see the actual attributes used.

=head2 Directory quotas

This is based on Maildir++. It consist on maintaining a file
(C<.pwpquota> by default) with the size of each file in the user's
directory. Every time a file is stored in the FTP space, a line is
added to the C<.pwpquota> file. The file is invalidated after a number
of operations or after a given time period.

This implementation is gentle to the NFS servers we use in our network
to host users' FTP space.

Currently, the recovery of space through the use of DELE commands
doesn't work reliably, as the size of the deleted file is not
available at the time the quota hook is called. However, a later
version will most likely correct this problem.

=head2 ARCHITECTURE

L<Net::FTPServer::PWP> provides a complete implementation for the FTP
server we required for our PWP scenario. It was built by extending the
existing L<Net::FTPServer> classes, as follows:

=over

=item C<Net::FTPServer::PWP::Server>

Inherits from C<Net::FTPServer>. Through the overloading of some key
methods, introduces the user authentication and the quota mechanisms.

=item C<Net::FTPServer::PWP::FileHandle>

Inherits from C<Net::FTPServer::Full::FileHandle>. Does not provide
any methods. It's there just for academic completeness.

=item C<Net::FTPServer::PWP::DirHandle>. 

Inherits from C<Net::FTPServer::Full::DirHandle>. Overrides the
C<-E<gt>delete()> method to provide a work-around for a bug found in
Darwin.

=back

The complete class hierarchy is shown below. The I<interesting>
classes or modules, are the ones marked with an asterisk.

  Net::FTPServer
  |
  + Net::FTPServer::Handle
  | |
  | +-Net::FTPServer::PWP::Handle (*)
  |
  +-Net::FTPServer::PWP::Server (*)
  |
  +-Net::FTPServer::Full
  |
  +-Net::FTPServer::Full::Server
  |
  +-Net::FTPServer::Full::DirHandle
  | |
  | +-Net::FTPServer::PWP::DirHandle (*)
  |
  +-Net::FTPServer::Full::FileHandle
    |
    +-Net::FTPServer::PWP::FileHandle (*)

Note that C<Net::FTPServer::PWP::FileHandle> and
C<Net::FTPServer::PWP::DirHandle> also inherit from
C<Net::FTPServer::PWP::Handle>. C<Net::FTPServer::PWP::Handle>
inherits from C<Net::FTPServer::Handle>.

This double inheritance is used to implement a jail, similar to the
use of C<chroot()>, which prevents users from interacting with files
or directories outside their PWP space.

=head2 CONFIGURATION

A few config file entries have been added. Please see
L<Net::FTPServer::PWP::Server> for a detailed discussion on the new
entries.

=head1 FILES

  /etc/ftpd.conf

=head1 HISTORY

$Id: PWP.pm,v 1.11 2003/04/01 15:50:41 lem Exp $

=over 8

=item 1.00

Original version; created by h2xs 1.21 with options

  -ACOXcfkn
	Net::FTPServer::PWP
	-v1.00
	-b
	5.5.0

=item 1.10

We can now hide the mount point from the client if instructed to do so
in the configuration file.

=item 1.20

Varios quota-related changes. See L<Net::FTPServer::PWP::Server> for
specific info.

Fixed typo in the docs that was causing POD errors.

=back

=head1 AUTHORS

Luis Munoz <luismunoz@cpan.org>, Manuel Picone <mpicone@cantv.net>

=head1 COPYRIGHT

Copyright (c) 2002, Luis Munoz and Manuel Picone

=head1 SEE ALSO

L<Net::FTPServer(3)>,
L<Net::FTPServer::PWP::Server(3)>,
L<perl(1)>

=cut
