
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Icecast2 Server API",
  "AUTHOR" => "Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::MockModule" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Icecast2",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Icecast2",
  "PREREQ_PM" => {
    "Carp" => 0,
    "LWP::UserAgent" => 0,
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "PHP::HTTPBuildQuery" => 0,
    "Safe::Isa" => 0,
    "Sub::Quote" => 0,
    "XML::Simple" => 0
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



