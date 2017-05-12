
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Verify BrowserID assertions.",
  "AUTHOR" => "Andrew Chilton <andychilton\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-BrowserID-Verify",
  "EXE_FILES" => [],
  "LICENSE" => "mozilla",
  "NAME" => "Net::BrowserID::Verify",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "HTTP::Request::Common" => 0,
    "JSON::Any" => 0,
    "LWP::Protocol::https" => 0,
    "LWP::UserAgent" => 0,
    "Mouse" => 0
  },
  "VERSION" => "0.003",
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



