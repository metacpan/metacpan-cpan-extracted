
use strict;
use warnings;

use 5.005;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Highly flexible CSV parser for large files",
  "AUTHOR" => "Adam Kennedy <adamk\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Parse-CSV",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Parse::CSV",
  "PREREQ_PM" => {
    "Carp" => 0,
    "IO::File" => "1.13",
    "Params::Util" => "1.00",
    "Text::CSV_XS" => "0.80",
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec::Functions" => 0,
    "Test::More" => 0
  },
  "VERSION" => "2.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Spec::Functions" => 0,
  "IO::File" => "1.13",
  "Module::Build" => "0.3601",
  "Params::Util" => "1.00",
  "Test::More" => 0,
  "Text::CSV_XS" => "0.80",
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



