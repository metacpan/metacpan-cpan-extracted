package Neo4j::Client;
use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '0.56';

sub Inline {
  # Work around https://github.com/PerlAlien/Alien-Build/issues/430
  {
    AUTO_INCLUDE => '#include "neo4j-client.h"',
    CCFLAGSEX    => __PACKAGE__->cflags_static,
    LIBS         => __PACKAGE__->libs_static,
  }
}

=head1 NAME

Neo4j::Client - Build and use the libneo4j-omni library

=head1 SYNOPSIS

With L<Alien::Base::Wrapper> for L<perlxs>:

  use Alien::Base::Wrapper 1.98 qw( WriteMakefile );

  WriteMakefile(
    alien_requires => [ 'Neo4j::Client' ],
    ...
  );

  # The wrapper will supply all compiler flags needed for
  # your Perl module to use libneo4j-omni automatically.

With L<Inline::C>:

  use Neo4j::Client 0.56;
  use Inline 0.56 with => 'Neo4j::Client';

With L<FFI::Platypus>:

  use FFI::CheckLib 0.25;
  use FFI::Platypus;

  my $ffi = FFI::Platypus->new;
  $ffi->lib( find_lib_or_die(
    alien => 'Neo4j::Client',
    lib   => 'neo4j-client',
  ));

Supplying compiler flags manually (not recommended):

  # for ExtUtils::MakeMaker
  use Config;
  WriteMakefile(
    CCFLAGS   => "$Config{ccflags} " . Neo4j::Client->cflags,
    LIBS      => Neo4j::Client->libs,
    ...

  # for Inline::C
  use Inline 0.51 C => Config =>
    CCFLAGSEX => Neo4j::Client->cflags,
    LIBS      => Neo4j::Client->libs;

  # for FFI::Platypus
  $ffi->lib( Neo4j::Client->dynamic_libs );

=head1 DESCRIPTION

Chris Leishman's
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> is a C
library for communication with a Neo4j server via the Bolt
protocol. A fork at L<https://github.com/majensen/libneo4j-omni> enables
the library to run on Neo4j versions up through 5.x.

Installing this module will attempt to build the API portion of the
library on your machine. C<libneo4j-omni>'s interactive shell and
documentation are not built. The install process will use the GNU
autotools C<autoconf-2.69>, C<automake-1.16.3>, and C<m4-1.4.18-patched>
which are bundled with this distro and are known to work on this library.
(These are required to build from ./configure for C<libneo4j-omni>.)

Thanks to the miracle of L<Alien::Build>, the library should always
contain OpenSSL support. This is already taken into account by the
methods in L<Alien::Base>, which are inherited by this module.
You shouldn't need to add any extra compiler flags for OpenSSL.

=head1 BUGS

The minimum supported version of OpenSSL is currently 1.1.0.
(L<GH #7|https://github.com/majensen/neoclient/issues/7>)

The C compiler must support the C<-Wpedantic> and C<-Wvla> options.
(L<GH #8|https://github.com/majensen/neoclient/issues/8>)

=head1 SEE ALSO

L<Neo4j::Bolt>.

=head1 AUTHOR

 Mark A. Jensen < majensen -at- cpan -dot- org >
 CPAN: MAJENSEN

=head1 ACKNOWLEDGMENT

Thanks L<ETJ|https://metacpan.org/author/ETJ> (a.k.a mohawk) for beaming me aboard.

=head1 LICENSE

This packaging software is Copyright (c) 2023 by Mark A. Jensen.

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

