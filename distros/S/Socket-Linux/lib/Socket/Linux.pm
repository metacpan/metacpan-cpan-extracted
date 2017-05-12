package Socket::Linux;

our $VERSION = '0.01';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(TCP_NODELAY TCP_MAXSEG TCP_CORK TCP_KEEPIDLE
		    TCP_KEEPINTVL TCP_KEEPCNT TCP_SYNCNT TCP_LINGER2
		    TCP_DEFER_ACCEPT TCP_WINDOW_CLAMP TCP_INFO
		    TCP_QUICKACK TCP_CONGESTION TCP_MD5SIG

		    TCPOPT_EOL TCPOPT_NOP TCPOPT_MAXSEG TCPOLEN_MAXSEG
		    TCPOPT_WINDOW TCPOLEN_WINDOW TCPOPT_SACK_PERMITTED
		    TCPOLEN_SACK_PERMITTED TCPOPT_SACK
		    TCPOPT_TIMESTAMP TCPOLEN_TIMESTAMP
		    TCPOLEN_TSTAMP_APPA TCPOPT_TSTAMP_HDR

		    TCP_MSS TCP_MAXWIN TCP_MAX_WINSHIFT SOL_TCP

		    TCPI_OPT_TIMESTAMPS TCPI_OPT_SACK TCPI_OPT_WSCALE
		    TCPI_OPT_ECN

		    TCP_MD5SIG_MAXKEYLEN);

require XSLoader;
XSLoader::load('Socket::Linux', $VERSION);


1;
__END__

=head1 NAME

Socket::Linux - Socket constants defined in Linux <netinet/tcp.h>

=head1 SYNOPSIS

  use Socket qw(IPPROTO_TCP);
  use Socket::Linux qw(TCP_KEEPINTVL TCP_KEEPIDLE TCP_KEEPCNT);

  setsockopt($sock, IPPROTO_TCP, TCP_KEEPIDLE,  10);
  setsockopt($sock, IPPROTO_TCP, TCP_KEEPINTVL, 10);
  setsockopt($sock, IPPROTO_TCP, TCP_KEEPCNT,    3);

=head1 DESCRIPTION

Exports to perl the constants defined in Linux <netinet/tcp.h>

=head1 SEE ALSO

L<Socket>, L<perlfunc>, L<tcp(7)>.

=head1 AUTHOR

Salvador FandiE<ntilde>o (sfandino@yahoo.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Qindel FormaciE<oacute>n y Servicios SL.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
