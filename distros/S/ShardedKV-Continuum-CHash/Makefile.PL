
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Continuum implementation based on Algorithm::ConsistentHash::CHash",
  "AUTHOR" => "Steffen Mueller <smueller\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "ShardedKV-Continuum-CHash",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "ShardedKV::Continuum::CHash",
  "PREREQ_PM" => {
    "Algorithm::ConsistentHash::CHash" => "0.00008",
    "Carp" => 0,
    "JSON::XS" => 0,
    "ShardedKV" => "0.18"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Algorithm::ConsistentHash::CHash" => "0.00008",
  "Carp" => 0,
  "JSON::XS" => 0,
  "ShardedKV" => "0.18"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



