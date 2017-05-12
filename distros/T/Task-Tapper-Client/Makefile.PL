
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - dependencies for test machine clients",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Tapper-Client",
  "EXE_FILES" => [],
  "LICENSE" => "open_source",
  "NAME" => "Task::Tapper::Client",
  "PREREQ_PM" => {
    "App::Bootstrap::Perl" => 0,
    "Tapper::Installer" => 0,
    "Tapper::PRC" => 0,
    "Tapper::Remote" => 0,
    "Tapper::TestSuite::AutoTest" => 0,
    "Tapper::TestSuite::Benchmark::Perl::Formance" => 0,
    "Tapper::TestSuite::HWTrack" => 0,
    "Tapper::TestSuite::Netperf" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



