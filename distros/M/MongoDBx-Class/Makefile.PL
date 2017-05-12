
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Flexible ORM for MongoDB databases",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MongoDBx-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MongoDBx::Class",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime::Format::W3CDTF" => 0,
    "Module::Load" => 0,
    "Module::Pluggable" => 0,
    "MongoDB" => "0.40",
    "MongoDB::Collection" => 0,
    "MongoDB::Connection" => 0,
    "MongoDB::Cursor" => 0,
    "MongoDB::Database" => 0,
    "MongoDB::MongoClient" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "version" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.030002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "DateTime" => 0,
  "DateTime::Format::W3CDTF" => 0,
  "Module::Load" => 0,
  "Module::Pluggable" => 0,
  "MongoDB" => "0.40",
  "MongoDB::Collection" => 0,
  "MongoDB::Connection" => 0,
  "MongoDB::Cursor" => 0,
  "MongoDB::Database" => 0,
  "MongoDB::MongoClient" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0,
  "Moose::Role" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "Test::More" => 0,
  "Time::HiRes" => 0,
  "Try::Tiny" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "version" => 0,
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



