
# Makefile.PL -- Makefile template for PerlPoint::Template::Traditional.
#
# This file is part of the "PerlPoint::Template::Traditional" module package.
# This package is free software, you can redistribute it
# and/or modify it under the terms of the Artistic License.

# load module
use ExtUtils::MakeMaker;

# the package requires modern perl
require 5.00503;

my $version='0.02';

# write makefile
$ok=WriteMakefile(
                  NAME         => 'PerlPoint::Template::Traditional',
                  ABSTRACT     => 'PerlPoint template engine in the tradition of pp2html.',
                  VERSION      => $version,
                  PREREQ_PM    => {
                                   PerlPoint::Constants => 0.17,
                                   PerlPoint::Template  => 0.01,
                                   Test::Harness        => 1.25,
                                   Test::More           => 0.11,
                                  },
                  dist         => {
                                   COMPRESS             => 'gzip -9',
                                   SUFFIX               => 'tgz',
                                  },
                 );

# provide additional informations
warn <<EOM if $ok;

Welcome to PerlPoint::Template::Traditional $version!

This distribution allows you to use an extended version of the
traditional pp2html template syntax in PerlPoint styles for the
new pp2tdo generator.

Users of a style based on this engine can use that style after
installation.

The installation is well prepared now, and you might run
"make test" and "make install".

EOM
