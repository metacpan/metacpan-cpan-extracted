
# Makefile.PL -- Makefile template for PerlPoint::Generator::XML.
#
# This file is part of the "PerlPoint::Generator::XML" module package.
# PerlPoint::Generator::XML is free software, you can redistribute it
# and/or modify it under the terms of the Artistic License.

# load module
use ExtUtils::MakeMaker;

# the package requires modern perl
require 5.00503;

my $version=0.04;

# write makefile
$ok=WriteMakefile(
                  NAME         => 'PerlPoint::Generator::XML',
                  ABSTRACT     => 'A PerlPoint generator (language module) for XML.',
                  VERSION      => $version,
                  PREREQ_PM    => {
                                   PerlPoint::Parser      => 0.40,
                                   PerlPoint::Constants   => 0.14,
                                   PerlPoint::Tags::Basic => 0.01,
                                   PerlPoint::Tags::HTML  => 0.01,
                                   XML::Generator         => 0.99,
                                   Test::Harness          => 1.25,
                                   Test::More             => 0.11,
                                  },
                  dist         => {
                                   COMPRESS               => 'gzip -9',
                                   SUFFIX                 => 'tgz',
                                  },
                 );

# provide additional informations
warn <<EOM if $ok;

Welcome to PerlPoint::Generator::XML $version!

With this package, you get an XML producer for
PerlPoint, including a default formatter. Please
search CPAN for more formatters on base of this
generator.

The installation is well prepared now,
and you might run "make test" and
"make install".


EOM
