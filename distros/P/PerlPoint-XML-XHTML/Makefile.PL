
# Makefile.PL -- Makefile template for PerlPoint::Generator::XML::XHTML.
#
# This file is part of the "PerlPoint::Generator::XML::XHTML" module package.
# This package is free software, you can redistribute it
# and/or modify it under the terms of the Artistic License.

# load module
use ExtUtils::MakeMaker;

# the package requires modern perl
require 5.00503;

my $version=0.07;

# write makefile
$ok=WriteMakefile(
                  NAME         => 'PerlPoint::XML::XHTML',
                  ABSTRACT     => 'PerlPoint fomatters to produce XHTML via the XML language module.',
                  VERSION      => $version,
                  PREREQ_PM    => {
                                   Digest::MD5               => 0,
                                   Memoize                   => 1,
                                   PerlPoint::Generator::XML => 0.04,

                                   # in version 0.10, the cloud module distribution lacks a lot of dependencies,
                                   # so we add them here
                                   Class::Data::Inheritable  => 0,
                                   Class::Accessor::Fast     => 0,
                                   Readonly                  => 0,
                                   HTML::TagCloud::Extended  => 0.10,

                                   Test::Harness             => 1.25,
                                   Test::More                => 0.11,
                                  },
                  dist         => {
                                   COMPRESS                  => 'gzip -9',
                                   SUFFIX                    => 'tgz',
                                  },
                 );

# provide additional informations
warn <<EOM if $ok;

Welcome to PerlPoint::Generator::XML::XHTML $version!

This distribution adds two HTML formatters to the XML
generator C<PerlPoint::Generator::XML>. Please see the
README file for more details.

The installation is well prepared now,
and you might run "make test" and
"make install".

EOM
