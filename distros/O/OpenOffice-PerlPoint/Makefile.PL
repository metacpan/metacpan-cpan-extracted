
# Makefile.PL -- Makefile template for OpenOffice::PerlPoint.
#
# OpenOffice::PerlPoint is free software, you can redistribute it
# and/or modify it under the terms of the Artistic License.

# load module
use ExtUtils::MakeMaker;

# perl requirements
require 5.00503;

# write makefile
$ok=WriteMakefile(
                  NAME         => 'OpenOffice::PerlPoint',
                  ABSTRACT     => 'A module to build OpenOffice to PerlPoint translators.',
                  VERSION_FROM => 'lib/OpenOffice/PerlPoint.pm',
                  PREREQ_PM    => {
                                   # for OpenOffice::PerlPoint
                                   OpenOffice::OODoc => 2.00,
                                   Net::Ping         => 1.00,
                                   Text::Wrapper     => 1.00,
                                   Text::Template    => 1.44,
                                   Storable          => 1.00,

                                   # for the tests
                                   Test::Harness     => 1.25,
                                   Test::More        => 0.11,
                                   Text::Diff        => 0.35,

                                   # for oo2pp
                                   Getopt::ArgvFile  => 1.06,
                                   Getopt::Long      => 2.32,
                                   Pod::Usage        => 1.14,
                                  },
                  dist         => {
                                   COMPRESS     => 'gzip -9',
                                   SUFFIX       => 'tgz',
                                  },
                  EXE_FILES    => [qw(oo2pp)],
                 );

