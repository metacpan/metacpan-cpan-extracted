use strict;
use warnings;

use 5.008000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Upload files to a Sonatype Nexus instance. Modelled on L<CPAN::Uploader>.",
  "AUTHOR" => "Sven Willenbuecher <sven.willenbuecher\@gmx.de>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Nexus-Uploader",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008000",
  "NAME" => "Nexus::Uploader",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "File::Slurp" => 0,
    "JSON" => 0,
    "Log::Any" => 0,
    "Moose" => 0,
    "REST::Client" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Pod::Coverage::TrustPod" => 0,
    "Test::More" => "1.00",
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0
  },
  "VERSION" => "1.0.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "File::Slurp" => 0,
  "JSON" => 0,
  "Log::Any" => 0,
  "Moose" => 0,
  "Pod::Coverage::TrustPod" => 0,
  "REST::Client" => 0,
  "Test::More" => "1.00",
  "Test::Pod" => 0,
  "Test::Pod::Coverage" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "utf8" => 0,
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
