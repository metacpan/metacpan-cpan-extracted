# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Bootstrap CPANPLUS with cpanm like BINGOS does",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Task-BINGOS-Bootstrap",
  "LICENSE" => "perl",
  "NAME" => "Task::BINGOS::Bootstrap",
  "PREREQ_PM" => {
    "CPANPLUS" => "0.9105",
    "CPANPLUS::Internals::Source::CPANIDX" => "0.04",
    "CPANPLUS::YACSmoke" => "0.62",
    "Test::Reporter::Transport::Socket" => "0.16"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CPANPLUS" => "0.9105",
  "CPANPLUS::Internals::Source::CPANIDX" => "0.04",
  "CPANPLUS::YACSmoke" => "0.62",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test::More" => 0,
  "Test::Reporter::Transport::Socket" => "0.16"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
