
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Measure suspend/resume cycle with external Arduino box",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-TestSuite-Benchmark-S3",
  "EXE_FILES" => [
    "bin/tapper-testsuite-benchmark-s3"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::TestSuite::Benchmark::S3",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Sys::Hostname" => 0,
    "Test::More" => 0,
    "Test::TAPv13" => 0,
    "WWW::Mechanize" => 0,
    "YAML::Syck" => 0,
    "strict" => 0,
    "warnings" => 0
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



