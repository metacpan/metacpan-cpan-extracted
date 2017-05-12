
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "RDF data flow pipeline",
  "AUTHOR" => "Jakob Vo\303\237 <voss\@gbv.de>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "RDF::Trine::Iterator" => 0,
    "RDF::Trine::Serializer::Turtle" => 0,
    "Test::More" => "0.88",
    "Test::RDF" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "RDF-Flow",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "RDF::Flow",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "File::Spec::Functions" => 0,
    "Log::Contextual" => 0,
    "Log::Contextual::WarnLogger" => 0,
    "POSIX" => 0,
    "RDF::Trine" => 0,
    "RDF::Trine::Model" => 0,
    "RDF::Trine::Parser" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "base" => 0,
    "parent" => 0,
    "re" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.178",
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



