##############################################################################
#
#  Net::Tools perl module
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
package Net::Tools;
use strict;

our $VERSION = '1.60';

1;

=pod

=head1 NAME

Net::Tools - socket and network functions, split from Data::Tools

=head1 SYNOPSIS

  use Net::Tools::Socket;            # socket I/O, length-prefixed messages
  use Net::Tools::Socket::Protocols; # serialized messages
  use Net::Tools::Socket::Pair;      # non-blocking messages over socketpair()
  use Net::Tools::Socket::Err;       # $SOCK_ERR, $SOCK_ERRSTR, SOCK_E_*

=head1 DESCRIPTION

Net::Tools itself has no functions, it only holds the package version. The
functions are in the sub-modules:

  * Net::Tools::Socket               (socket I/O, length-prefixed messages)
  * Net::Tools::Socket::Protocols    (serialized messages over Net::Tools::Socket)
  * Net::Tools::Socket::Pair         (non-blocking messages over socketpair())
  * Net::Tools::Socket::Err          (error codes shared by the socket modules)

Up to version 1.55 these modules were part of Data::Tools as
Data::Tools::Socket, Data::Tools::Socket::Protocols,
Data::Tools::Socket::Pair and Data::Tools::Socket::Err. Only the package
names changed, replace "Data::Tools::Socket" with "Net::Tools::Socket".

=head1 REQUIRED MODULES

  * Data::Tools (Net::Tools::Socket::Protocols only)

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-net-tools.git

  git clone https://github.com/cade-vs/perl-net-tools.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/

=cut
