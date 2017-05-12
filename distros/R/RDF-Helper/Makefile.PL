
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provide a consistent, high-level API for working with RDF with Perl",
  "AUTHOR" => "Kip Hampton <khampton\@totalcinema.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "RDF-Helper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "RDF::Helper",
  "PREREQ_PM" => {
    "Class::Load" => "0.20",
    "Data::UUID" => 0,
    "Moose" => "1.09",
    "MooseX::Aliases" => 0,
    "RDF::Query" => "2.905",
    "Test::Simple" => "0.88",
    "URI" => 0
  },
  "VERSION" => "2.01",
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



