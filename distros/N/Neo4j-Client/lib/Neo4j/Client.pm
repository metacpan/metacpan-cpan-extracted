package Neo4j::Client;
use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '0.40';

=head1 NAME

Neo4j::Client - Build and use the libneo4j-client library

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use Neo4j::Client;
 
 WriteMakefile(
   LIBS => Neo4j::Client->libs,
   CCFLAGS => Neo4j::Client->cflags,
   ...
 );

=head1 DESCRIPTION

Chris Leishman's
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> is a C
library for communication with a Neo4j server via the Bolt
protocol. 

Installing this module will attempt to build the API portion of the
library on your machine. C<libneo4j-client>'s interactive shell and
documentation are not built. The install process will use the GNU
autotools C<autoconf-2.69>, C<automake-1.16.3>, and C<m4-1.4.18-patched>
which are bundled with this distro and are known to work on this library.
(These are required to build from ./configure for C<libneo4j-client>.)

Thanks to the miracle of L<Alien::Build>, the library should always
contain OpenSSL support.


=head1 SEE ALSO

L<Neo4j::Bolt>.

=head1 AUTHOR

 Mark A. Jensen < majensen -at- cpan -dot- org >
 CPAN: MAJENSEN

=head1 ACKNOWLEDGMENT

Thanks L<ETJ|https://metacpan.org/author/ETJ> (a.k.a mohawk) for beaming me aboard.

=head1 LICENSE

This packaging software is Copyright (c) 2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

The L<libneo4j-client|https://github.com/clieshm/libneo4j-client> software 
is Copyright (c) by Chris Leishman. 

It is free software, licensed under:

  The Apache License, Version 2.0, January 2004

The bundled GNU Autotools autoconf, automake, and m4 are free software, 
licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

1;

