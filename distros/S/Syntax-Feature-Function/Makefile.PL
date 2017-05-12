
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a function keyword",
  "AUTHOR" => "Robert 'phaylon' Sedlacek <rs\@474.at>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Syntax-Feature-Function",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Syntax::Feature::Function",
  "PREREQ_PM" => {
    "B::Hooks::EndOfScope" => "0.08",
    "Carp" => 0,
    "Function::Parameters" => "0.04",
    "Import::Into" => "1.001000",
    "namespace::clean" => "0.14",
    "syntax" => "0.001"
  },
  "VERSION" => "0.002",
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



