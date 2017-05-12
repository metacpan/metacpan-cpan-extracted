package Net::IP::CMatch;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
                 match_ip
                 );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Net::IP::CMatch', $VERSION);

1;

__END__

=head1 NAME

Net::IP::CMatch - Efficiently match IP addresses against IP ranges with C.

=head1 SYNOPSIS

  use Net::IP::CMatch;
  my $match = match_ip( $ip_addr, $match_ip1, $match_ip2, ... );

=head1 DESCRIPTION

Net::IP::CMatch is based upon, and does the same thing as Net::IP::Match.
The unconditionally exported subroutine 'match_ip' determines if the
ip to match ( first argument ) matches any of the subsequent ip arguments.
Match arguments may be absolute quads, as '127.0.0.1', or contain
mask bits as '111.245.76.248/29'.
A true return value indicates a match. It was written in C, rather than
a macro, preprocessed
through Perl's source filter mechanism ( as is Net::IP::Match ), so that
the ip arguments could be traditional perl scalars. The C code is
lean and mean ( IMHO ).

=head2 Example in Apache/mod_perl

I use this module in my Apache server's mod_perl DB logging script to
determine if an incoming IP is 'remote' or 'local'. First, I set up
some variables in httpd.conf:

  PerlSetvar DBILogger_local_ips '222.234.52.192/29'
  PerlAddvar DBILogger_local_ips '111.245.76.248/29'
  PerlAddvar DBILogger_local_ips '10.0.0.0/24'
  PerlAddvar DBILogger_local_ips '172.16.0.0/12'
  PerlAddvar DBILogger_local_ips '192.168.0.0/16'
  PerlAddvar DBILogger_local_ips '127.0.0.1'

These are the ip addresses I want to be considered local. In the
mod_perl module:

  my @local_ips = $r->dir_config( "DBILogger_local_ips" );
  my $local = match_ip( $incoming_ip, @local_ips );

Now $local is just that, and I set the database key accordingly.

=head2 EXPORT

'match_ip', unconditionally.

=head1 SEE ALSO

L<Net::IP::Match> by Marcel GrE<uuml>nauer.

=head1 AUTHOR

Beau E. Cox, E<lt>beaucox@hawaii.rr.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Beau E. Cox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
