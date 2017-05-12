
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Character n-gram tokenizer for Search::Fulltext",
  "AUTHOR" => "Koichi SATOH <sekia\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Search-Fulltext-Tokenizer-Ngram",
  "EXE_FILES" => [],
  "LICENSE" => "mit",
  "NAME" => "Search::Fulltext::Tokenizer::Ngram",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Scalar::Util" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Search::Fulltext" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/Search/Fulltext/Tokenizer/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Scalar::Util" => 0,
  "Search::Fulltext" => 0,
  "Test::More" => 0,
  "parent" => 0,
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



