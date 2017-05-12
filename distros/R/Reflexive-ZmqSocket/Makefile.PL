
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a reflexy way to talk over ZeroMQ sockets",
  "AUTHOR" => "Nicholas R. Perez <nperez\@cpan.org>, Steffen Mueller <smueller\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Reflex::Trait::Watched" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Reflexive-ZmqSocket",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Reflexive::ZmqSocket",
  "PREREQ_PM" => {
    "Errno" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Reflex::Base" => 0,
    "Reflex::Event" => 0,
    "Reflex::Role::Readable" => 0,
    "Reflex::Role::Writable" => 0,
    "Try::Tiny" => 0,
    "ZeroMQ::Constants" => 0,
    "ZeroMQ::Context" => 0,
    "ZeroMQ::Socket" => 0
  },
  "VERSION" => "1.130710",
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



