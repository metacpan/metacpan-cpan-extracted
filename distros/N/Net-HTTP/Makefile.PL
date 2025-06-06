# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.006002;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Low-level HTTP connection (client)",
  "AUTHOR" => "Gisle Aas <gisle\@activestate.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Net-HTTP",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006002",
  "NAME" => "Net::HTTP",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Compress::Raw::Zlib" => 0,
    "IO::Socket::INET" => 0,
    "IO::Uncompress::Gunzip" => 0,
    "URI" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Select" => 0,
    "Socket" => 0,
    "Test::More" => 0
  },
  "VERSION" => "6.23",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Compress::Raw::Zlib" => 0,
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Select" => 0,
  "IO::Socket::INET" => 0,
  "IO::Uncompress::Gunzip" => 0,
  "Socket" => 0,
  "Test::More" => 0,
  "URI" => 0,
  "base" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
