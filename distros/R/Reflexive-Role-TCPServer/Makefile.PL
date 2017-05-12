
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a consumable Reflex-based multiplexing TCP server behavior",
  "AUTHOR" => "Nicholas R. Perez <nperez\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Moose" => 0,
    "POSIX" => 0,
    "Reflex::Base" => 0,
    "Reflex::Client" => 0,
    "Test::More" => 0,
    "Test::TCP" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Reflexive-Role-TCPServer",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Reflexive::Role::TCPServer",
  "PREREQ_PM" => {
    "IO::Socket::INET" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "POE::Filter::Stream" => 0,
    "Reflex::Callbacks" => 0,
    "Reflex::Role" => 0,
    "Reflex::Role::Accepting" => 0,
    "Reflexive::Role::Collective" => 0,
    "Reflexive::Stream::Filtering" => 0,
    "Try::Tiny" => 0
  },
  "VERSION" => "1.140030",
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



