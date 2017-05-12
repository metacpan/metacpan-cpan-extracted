
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Wrapper for Benchmark::Perl::Formance",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-TestSuite-Benchmark-Perl-Formance",
  "EXE_FILES" => [
    "bin/tapper-testsuite-benchmark-perlformance"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::TestSuite::Benchmark::Perl::Formance",
  "PREREQ_PM" => {
    "Benchmark::Perl::Formance" => 0,
    "Config" => 0,
    "Getopt::Long" => 0,
    "IO::Socket::INET" => 0,
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



