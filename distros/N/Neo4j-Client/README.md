# NAME

Neo4j::Client - Build and use the libneo4j-omni library

# SYNOPSIS

With [Alien::Base::Wrapper](https://metacpan.org/pod/Alien::Base::Wrapper) for [perlxs](https://metacpan.org/pod/perlxs):

    use Alien::Base::Wrapper 1.98 qw( WriteMakefile );

    WriteMakefile(
      alien_requires => [ 'Neo4j::Client' ],
      ...
    );

    # The wrapper will supply all compiler flags needed for
    # your Perl module to use libneo4j-omni automatically.

With [Inline::C](https://metacpan.org/pod/Inline::C):

    use Neo4j::Client 0.56;
    use Inline 0.56 with => 'Neo4j::Client';

With [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus):

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

# DESCRIPTION

Chris Leishman's
[libneo4j-client](https://github.com/cleishm/libneo4j-client) is a C
library for communication with a Neo4j server via the Bolt
protocol. A fork at <https://github.com/majensen/libneo4j-omni> enables
the library to run on Neo4j versions up through 5.x.

Installing this module will attempt to build the API portion of the
library on your machine. `libneo4j-omni`'s interactive shell and
documentation are not built. The install process will use the GNU
autotools `autoconf-2.69`, `automake-1.16.3`, and `m4-1.4.18-patched`
which are bundled with this distro and are known to work on this library.
(These are required to build from ./configure for `libneo4j-omni`.)

Thanks to the miracle of [Alien::Build](https://metacpan.org/pod/Alien::Build), the library should always
contain OpenSSL support. This is already taken into account by the
methods in [Alien::Base](https://metacpan.org/pod/Alien::Base), which are inherited by this module.
You shouldn't need to add any extra compiler flags for OpenSSL.

# BUGS

The minimum supported version of OpenSSL is currently 1.1.0.
([GH #7](https://github.com/majensen/neoclient/issues/7))

The C compiler must support the `-Wpedantic` and `-Wvla` options.
([GH #8](https://github.com/majensen/neoclient/issues/8))

# SEE ALSO

[Neo4j::Bolt](https://metacpan.org/pod/Neo4j::Bolt).

# AUTHOR

    Mark A. Jensen < majensen -at- cpan -dot- org >
    CPAN: MAJENSEN

# ACKNOWLEDGMENT

Thanks [ETJ](https://metacpan.org/author/ETJ) (a.k.a mohawk) for beaming me aboard.

# LICENSE

This packaging software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

The [libneo4j-client](https://github.com/clieshm/libneo4j-client) software 
is Copyright (c) by Chris Leishman. 

It is free software, licensed under:

    The Apache License, Version 2.0, January 2004

The bundled GNU Autotools autoconf, automake, and m4 are free software, 
licensed under:

    The GNU General Public License, Version 3, June 2007
