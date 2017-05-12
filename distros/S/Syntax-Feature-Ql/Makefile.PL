
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Turns a quoted string into a single line",
  "AUTHOR" => "Robert 'phaylon' Sedlacek <rs\@474.at>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Syntax-Feature-Ql",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Syntax::Feature::Ql",
  "PREREQ_PM" => {
    "B::Hooks::EndOfScope" => "0.09",
    "Devel::Declare" => "0.006007",
    "Devel::Declare::Context::Simple" => 0,
    "Sub::Install" => "0.925",
    "Syntax::Feature::Simple::V2" => 0,
    "aliased" => 0,
    "namespace::clean" => 0,
    "strictures" => 1,
    "syntax" => "0.003"
  },
  "VERSION" => "0.001000",
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



