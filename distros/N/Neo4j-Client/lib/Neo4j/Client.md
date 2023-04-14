# NAME

Neo4j::Client - Build and use the libneo4j-client library

# SYNOPSIS

    use ExtUtils::MakeMaker;
    use Neo4j::Client;
    
    WriteMakefile(
      LIBS => Neo4j::Client->libs,
      CCFLAGS => Neo4j::Client->cflags,
      ...
    );

# DESCRIPTION

Chris Leishman's
[libneo4j-client](https://github.com/cleishm/libneo4j-client) is a C
library for communication with a Neo4j server via the Bolt
protocol. A fork at [https://github.com/majensen/libneo4j-client](https://github.com/majensen/libneo4j-client) enables
the library to run on Neo4j versions up through 5.0.x.

Installing this module will attempt to build the API portion of the
library on your machine. `libneo4j-client`'s interactive shell and
documentation are not built. The install process will use the GNU
autotools `autoconf-2.69`, `automake-1.16.3`, and `m4-1.4.18-patched`
which are bundled with this distro and are known to work on this library.
(These are required to build from ./configure for `libneo4j-client`.)

Thanks to the miracle of [Alien::Build](https://metacpan.org/pod/Alien::Build), the library should always
contain OpenSSL support.

# SEE ALSO

[Neo4j::Bolt](https://github.com/majensen/perlbolt)

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
