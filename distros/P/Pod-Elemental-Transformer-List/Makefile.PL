
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "transform :list regions into =over/=back to save typing",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Elemental-Transformer-List",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Pod::Elemental::Transformer::List",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Pod::Elemental::Element::Pod5::Command" => 0,
    "Pod::Elemental::Transformer" => "0.101620",
    "Pod::Elemental::Types" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Pod::Elemental" => 0,
    "Pod::Elemental::Transformer::Pod5" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.96",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.102000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Moose" => 0,
  "Pod::Elemental" => 0,
  "Pod::Elemental::Element::Pod5::Command" => 0,
  "Pod::Elemental::Transformer" => "0.101620",
  "Pod::Elemental::Transformer::Pod5" => 0,
  "Pod::Elemental::Types" => 0,
  "Test::Differences" => 0,
  "Test::More" => "0.96",
  "namespace::autoclean" => 0,
  "strict" => 0,
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



