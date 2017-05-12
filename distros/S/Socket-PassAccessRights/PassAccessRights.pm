# Copyright (c) 2000 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
# This module may be copied under the same terms as the perl itself.

package Socket::PassAccessRights;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.03';

bootstrap Socket::PassAccessRights $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Socket::PassAccessRights - Perl extension for BSD style file descriptor
                           passing via Unix domain sockets

=head1 SYNOPSIS

  use Socket::PassAccessRights;
  Socket::PassAccessRights::sendfd(fileno(SOCKET), fileno(SEND_ME)) or die;
  $fd = Socket::PassAccessRights::recvfd(fileno(SOCKET)) or die;
  open FD, ">&=$fd" or die "$!";  # convert int fd to file handle

=head1 DESCRIPTION

Implements passing access rights (i.e. file descritors) over Unix
domain sockets. Only one fd can be passed at one time and no other
data can be sent in the same operation (operation itself involves
sending exactly one byte of data to solve EOF detection anomaly).

See test.pl and examples directory for usage examples.

=head1 PLATFORMS

This code has only been tested on

    * Linux-2.0.38 with glibc-2.0.7 (libc.so.6) and libc.so.5 (BSD4.4 style)
    * Linux-2.2.14 with glibc-2.0.7 (libc.so.6) (BSD4.4 style)
    * Solaris-2.6 using gcc (BSD4.3 style)

Specifically, the code from [Stevens] did not work out of the box. I had
to rename msg.msg_accrights* to msg.control* and send at least one byte.
General impression from net is that file descripto passing code seems
to be buggy - not just in Linux, but on FreeBSD, too.

=head1 AUTHOR AND COPYRIGHT

Sampo Kellomaki <sampo@iki.fi>

Copyright (c) 2000 by Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.

This module may be copied under the same terms as perl itself.

=head1 SEE ALSO

Home page: http://www.bacus.pt/Net_SSLeay/modules.html
perl(1)
recvmsg(2)
sendmsg(2)
Richard Stevens: Unix Network Programming, Prentice Hall, 1990; chapter 6.10.
/usr/include/socketbits.h
/usr/include/sys/socket.h

=cut
