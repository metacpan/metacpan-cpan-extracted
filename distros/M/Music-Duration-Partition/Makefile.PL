# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Partition a musical duration into rhythmic phrases",
  "AUTHOR" => "Gene Boggs <gene\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Music-Duration-Partition",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Music::Duration::Partition",
  "PREREQ_PM" => {
    "List::Util" => 0,
    "MIDI::Util" => 0,
    "Math::Random::Discrete" => 0,
    "Moo" => 2,
    "Music::Duration" => 0,
    "constant" => 0,
    "namespace::clean" => 0,
    "strictures" => 2
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0823",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "MIDI::Util" => 0,
  "Math::Random::Discrete" => 0,
  "Moo" => 2,
  "Music::Duration" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "constant" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "strictures" => 2,
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
