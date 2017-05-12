
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provide a localizable dropdown where users can select a country",
  "AUTHOR" => "Renee Baecker <module\@renee-baecker.de>, Heiko Jansen <jansen\@hbz-nrw.de>, Skye Shaw <sshaw AT lucas.cis.temple.edu>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mojolicious-Plugin-CountryDropDown",
  "EXE_FILES" => [],
  "LICENSE" => "gpl",
  "NAME" => "Mojolicious::Plugin::CountryDropDown",
  "PREREQ_PM" => {
    "List::MoreUtils" => 0,
    "Locale::Codes" => "3.20",
    "Locale::Country::Multilingual" => "0.23",
    "Mojolicious" => "2.00",
    "Unicode::Collate" => 0
  },
  "VERSION" => "0.06",
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



