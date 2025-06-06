
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.019.
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple Stat on arrayref, like sum, mean, calc rate, etc",
  "AUTHOR" => "abbypan <abbypan\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SimpleR-Stat",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SimpleR::Stat",
  "PREREQ_PM" => {
    "Tie::Autotie" => 0,
    "Tie::IxHash" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Tie::Autotie" => 0,
  "Tie::IxHash" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



