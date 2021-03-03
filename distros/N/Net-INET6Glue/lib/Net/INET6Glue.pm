package Net::INET6Glue;
$VERSION = "0.604";
use Net::INET6Glue::INET_is_INET6;
use Net::INET6Glue::FTP;
1;

=head1 NAME

Net::INET6Glue - Make common modules IPv6 ready by hotpatching

=head1 SYNOPSIS

 use Net::INET6Glue; # include all glue
 use LWP;
 use Net::SMTP;
 use Net::FTP;
 ..

=head1 DESCRIPTION

L<Net::INET6Glue> is a collection of modules to make common modules IPv6 ready
by hotpatching them.

Unfortunatly the current state of IPv6 support in perl is that no IPv6 support
is in the core and that a lot of important modules (like L<Net::FTP>,
L<Net::SMTP>, L<LWP>,...) do not support IPv6 even if the modules for IPv6
sockets like L<Socket6>, L<IO::Socket::IP> or L<IO::Socket::INET6> are available.

This module tries to mitigate this by hotpatching.
Currently the following submodules are available:

=over 4

=item L<Net::INET6Glue::INET_is_INET6>

Makes L<IO::Socket::INET> behave like L<IO::Socket::IP> (with fallback to
like L<IO::Socket::INET6>), especially make it capable to create IPv6 sockets. 
This makes L<LWP>, L<Net::SMTP> and others IPv6 capable.

=item L<Net::INET6Glue::FTP>

Hotpatches L<Net::FTP> to support EPRT and EPSV commands which are needed to
deal with FTP over IPv6. Also loads L<Net::INET6Glue::INET_is_INET6>.

=back

=head1 COPYRIGHT

This module and the modules in the Net::INET6Glue Hierarchy distributed together 
with this module are copyright (c) 2008..2014, Steffen Ullrich.
All Rights Reserved.
These modules are free software. They may be used, redistributed and/or modified 
under the same terms as Perl itself.

