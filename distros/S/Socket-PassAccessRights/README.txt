Socket::PassAccessRights - Perl extension for BSD style file descriptor
                           passing via Unix domain sockets

28.1.2000, Sampo Kellomaki <sampo@iki.fi>

Home page: http://www.bacus.pt/Net_SSLeay/modules.html

  use Socket::PassAccessRights;
  Socket::PassAccessRights::sendfd(fileno(SOCKET), fileno(SEND_ME)) or die;
  $fd = Socket::PassAccessRights::recvfd(fileno(SOCKET)) or die;

Implements passing access rights (i.e. file descritors) over Unix
domain sockets as decribed in

  Richard Stevens: Unix Network Programming, Prentice Hall, 1990; chapter 6.10.

See pod documentation for details.

INSTALL
	perl Makefile.PL
	make
	make test
	make install  # probably have to su to root first

/* Tested to work on perl 5.005_03
 *   Linux-2.2.14 glibc-2.0.7 (libc.so.6) i586  BSD4.4
 *   Linux-2.0.38 glibc-2.0.7 (libc.so.6) i586  BSD4.4
 *   SunOS-5.6, gcc-2.7.2.3, Sparc BSD4.3
 * see also: linux/net/unix/af_unix.c
 */

Copyright (c) 2000 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.

You may use and distribute Socket::PassAccessRights under the same terms
and conditions as the perl itself.

--Sampo
