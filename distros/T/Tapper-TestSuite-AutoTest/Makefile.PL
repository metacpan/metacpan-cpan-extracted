
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Complete OS testing in a box via autotest",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-TestSuite-AutoTest",
  "EXE_FILES" => [
    "bin/tapper-testsuite-autotest"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::TestSuite::AutoTest",
  "PREREQ_PM" => {
    "Archive::Tar" => 0,
    "Cwd" => 0,
    "Digest::MD5" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "Getopt::Long" => 0,
    "IO::Socket::INET" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "MooseX::Log::Log4perl" => 0,
    "Sys::Hostname" => 0,
    "YAML::Syck" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.1.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



