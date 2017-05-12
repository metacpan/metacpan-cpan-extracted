
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Network performance measurements",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-TestSuite-Netperf",
  "EXE_FILES" => [
    "bin/tapper-testsuite-netperf-client",
    "bin/tapper-testsuite-netperf-server"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::TestSuite::Netperf",
  "PREREQ_PM" => {
    "IO::Handle" => 0,
    "IO::Socket::INET" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "MooseX::Log::Log4perl" => 0,
    "YAML" => 0
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



