
# Makefile.PL -- Makefile template for PerlPoint::Template::TT2.
#
# This file is part of the "PerlPoint::Template::TT2" module package.
# This package is free software, you can redistribute it
# and/or modify it under the terms of the Artistic License.

# load module
use ExtUtils::MakeMaker;

# the package requires modern perl
require 5.00503;

my $version='0.02';

# write makefile
$ok=WriteMakefile(
                  NAME         => 'PerlPoint::Template::TT2',
                  ABSTRACT     => 'PerlPoint Template Toolkit 2 templates available for PerlPoint.',
                  VERSION      => $version,
                  PREREQ_PM    => {
                                   PerlPoint::Constants => 0.17,
                                   PerlPoint::Template  => 0.01,
                                   Template             => 0,
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

Welcome to PerlPoint::Template::TT2 $version!

The installation is well prepared now,
and you might run "make test" and
"make install".

EOM
