
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Perl interface for gandi api",
  "AUTHOR" => "Natal Ng\303\251tal",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Net-Gandi",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Gandi",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Traits" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::URI" => 0,
    "Params::Check" => 0,
    "XMLRPC::Lite" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.122180",
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



