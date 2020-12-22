# Neo4j::Client - portable [libneo4j-client](https://github.com/cleishm/libneo4j-client) library for Perl

Neo4j::Client is a Perl module that attempts to portably build the Neo4j Bolt protocol C library from @cleishm's [libneo4j-client](https://github.com/cleishm/libneo4j-client). The installation sequesters the library in the secret Perl data directories (i.e., `.../auto/...`), so that it doesn't affect other installations.

It is, in fact, a complex kludge to enable [Neo4j::Bolt](https://github.com/majensen/perlbolt) run reliably across 'Nix platforms.

The module itself has one functionality - to provide linker and compiler flags that point to the built library.

A script `neoclient.pl` is also installed, to enable working with the library on the command line. E.g.,

	$ cc $(neoclient.pl --libs --cc) trybolt.c

It should install successfully on Darwin and Un*x. It is currently very unlikely to install on Windows (but try Cygwin).





