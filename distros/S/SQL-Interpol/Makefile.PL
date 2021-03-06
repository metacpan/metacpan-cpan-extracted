# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.034.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "interpolate Perl variables into SQL statements",
  "AUTHOR" => "Aristotle Pagaltzis <pagaltzis\@gmx.de>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "SQL-Interpol",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "SQL::Interpol",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter::Tidy" => 0,
    "Object::Tiny::Lvalue" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "1.103",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "Exporter::Tidy" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Find" => 0,
  "File::Temp" => 0,
  "Object::Tiny::Lvalue" => 0,
  "Test::Differences" => 0,
  "Test::More" => "0.88",
  "constant" => 0,
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
