# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.038.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "subclass for supporting Tasks and Bundles",
  "AUTHOR" => "Jonas B. Nielsen <jonasbn\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.42"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "Module::Build" => "0.30"
  },
  "DISTNAME" => "Module-Build-Bundle",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Module::Build::Bundle",
  "PREREQ_PM" => {
    "CPAN::Meta::YAML" => 0,
    "Carp" => 0,
    "Cwd" => 0,
    "English" => 0,
    "Env" => 0,
    "File::Slurp" => 0,
    "Module::Build" => "0.42",
    "Tie::IxHash" => 0
  },
  "TEST_REQUIRES" => {
    "File::Copy" => 0,
    "File::Spec" => 0,
    "File::Tempdir" => 0,
    "File::stat" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::Kwalitee" => "1.21",
    "Test::MockObject::Extends" => 0,
    "Test::More" => "0.88",
    "Test::Pod" => "1.41",
    "Test::Pod::Coverage" => "1.08",
    "Text::Soundex" => 0
  },
  "VERSION" => "0.17",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Meta::YAML" => 0,
  "Carp" => 0,
  "Cwd" => 0,
  "English" => 0,
  "Env" => 0,
  "File::Copy" => 0,
  "File::Slurp" => 0,
  "File::Spec" => 0,
  "File::Tempdir" => 0,
  "File::stat" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.42",
  "Pod::Coverage::TrustPod" => 0,
  "Test::Class" => 0,
  "Test::Exception" => 0,
  "Test::Kwalitee" => "1.21",
  "Test::MockObject::Extends" => 0,
  "Test::More" => "0.88",
  "Test::Pod" => "1.41",
  "Test::Pod::Coverage" => "1.08",
  "Text::Soundex" => 0,
  "Tie::IxHash" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
