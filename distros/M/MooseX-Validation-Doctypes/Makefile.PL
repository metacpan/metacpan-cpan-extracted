
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "validation of nested data structures with Moose type constraints",
  "AUTHOR" => "Jesse Luehrs <doy at cpan dot org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "MooseX::Types::Email" => 0,
    "MooseX::Types::URI" => 0,
    "Test::More" => "0.88",
    "Test::Requires" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MooseX-Validation-Doctypes",
  "EXE_FILES" => [],
  "LICENSE" => "mit",
  "NAME" => "MooseX::Validation::Doctypes",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Devel::PartialDump" => 0,
    "Moose" => 0,
    "Moose::Meta::TypeConstraint" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.05",
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



