
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl module to extract fields from objects",
  "AUTHOR" => "Paul Boyd <pboyd\@dev3l.net>",
  "BUILD_REQUIRES" => {
    "Moose" => 0,
    "MooseX::Test::Role" => "0.02",
    "Test::Deep" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Parse-FieldPath",
  "EXE_FILES" => [
    "bin/rebuild_grammar.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Parse::FieldPath",
  "PREREQ_PM" => {
    "Hash::Merge" => "0.11",
    "List::Util" => 0,
    "Parse::RecDescent" => "1.963",
    "Scalar::Util" => 0
  },
  "VERSION" => "0.005",
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



