# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "N dimensional version of functions",
  "AUTHOR" => "Diab Jerius <djerius\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "PDL-FuncND",
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "PDL::FuncND",
  "PREREQ_PM" => {
    "Carp" => 0,
    "PDL::Constants" => 0,
    "PDL::Exporter" => 0,
    "PDL::LiteF" => 0,
    "PDL::Math" => 0,
    "PDL::MatrixOps" => 0,
    "PDL::Options" => 0,
    "PDL::Transform" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Math::Trig" => 0,
    "PDL" => 0,
    "Test2::V0" => 0,
    "Test::More" => 0,
    "Test::Trap" => 0
  },
  "VERSION" => "0.13",
  "test" => {
    "TESTS" => "t/*.t t/01-funcs/*.t t/02-api/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Math::Trig" => 0,
  "PDL" => 0,
  "PDL::Constants" => 0,
  "PDL::Exporter" => 0,
  "PDL::LiteF" => 0,
  "PDL::Math" => 0,
  "PDL::MatrixOps" => 0,
  "PDL::Options" => 0,
  "PDL::Transform" => 0,
  "Scalar::Util" => 0,
  "Test2::V0" => 0,
  "Test::More" => 0,
  "Test::Trap" => 0,
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
