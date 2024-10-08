#
# This file is part of MooseX-CurriedDelegation
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Curry your delegations with methods",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "MooseX-CurriedDelegation",
  "LICENSE" => "lgpl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "MooseX::CurriedDelegation",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "MooseX::Util" => 0,
    "aliased" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::Moose" => 0,
    "Test::Moose::More" => 0,
    "Test::More" => "0.94",
    "blib" => "1.01"
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0,
  "Moose::Role" => 0,
  "MooseX::Util" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::Moose" => 0,
  "Test::Moose::More" => 0,
  "Test::More" => "0.94",
  "aliased" => 0,
  "blib" => "1.01",
  "namespace::autoclean" => 0,
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
