
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interact with FileMaker services",
  "AUTHOR" => "Squeeks <squeek\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-FileMaker",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::FileMaker",
  "PREREQ_PM" => {
    "DateTime::Format::CLDR" => 0,
    "LWP" => 0,
    "URI" => 0,
    "XML::Twig" => "3.33"
  },
  "VERSION" => "0.064",
  "test" => {
    "TESTS" => "t/*.t t/00_load/*.t t/01_xml/*.t t/02_error/*.t t/03_resultset/*.t t/04_field_definition/*.t t/05_row/*.t"
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



