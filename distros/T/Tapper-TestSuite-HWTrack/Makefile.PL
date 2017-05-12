
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Report hardware meta information",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-TestSuite-HWTrack",
  "EXE_FILES" => [
    "bin/tapper-testsuite-hwtrack"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::TestSuite::HWTrack",
  "PREREQ_PM" => {
    "File::ShareDir" => 0,
    "File::Temp" => 0,
    "IO::Select" => 0,
    "IO::Socket::INET" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "Sys::Hostname" => 0,
    "Tapper::Base" => 0,
    "XML::Simple" => 0,
    "YAML" => 0,
    "aliased" => 0
  },
  "VERSION" => "4.1.1",
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



