#! perl

use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDF::Table',
    VERSION_FROM      => 'lib/PDF/Table.pm', # finds $VERSION
    MIN_PERL_VERSION  => 5.010000, # Perl 5.10 minimum
    LICENSE           => 'perl_5',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      # modules you MAY have to (or want to) install:
      #  Build and install:
      #   Test::Pod (can test without)
      #   Test::CheckManifest (can test without)
      #   Test::More (required)
      #  Run time:
      #   Pod::Simple::HTML (for POD->HTML generation, optional)
      #   Carp (required)
      #  And of course, PDF::API2 *OR* PDF::Builder (both can be installed)
    ABSTRACT_FROM     => 'lib/PDF/Table.pm', # retrieve abstract from module
    AUTHOR            => 'Phil Perry <omega@cpan.org>',
    META_MERGE        => {
        resources => {
            bugtracker => 'https://github.com/PhilterPaper/PDF-Table/issues',
            repository => 'https://github.com/PhilterPaper/PDF-Table',
        },
    },
);
