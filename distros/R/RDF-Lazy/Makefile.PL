
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Lazy typing access to RDF data",
  "AUTHOR" => "Jakob Vo\303\237 <voss\@gbv.de>",
  "BUILD_REQUIRES" => {
    "RDF::Trine::NamespaceMap" => 0,
    "Template" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "RDF-Lazy",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "RDF::Lazy",
  "PREREQ_PM" => {
    "CGI" => 0,
    "Carp" => 0,
    "RDF::NS" => 0,
    "RDF::Trine" => 0,
    "RDF::Trine::Model" => 0,
    "RDF::Trine::Parser" => 0,
    "RDF::Trine::Serializer::RDFJSON" => 0,
    "RDF::Trine::Serializer::RDFXML" => 0,
    "RDF::Trine::Serializer::Turtle" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.081",
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



