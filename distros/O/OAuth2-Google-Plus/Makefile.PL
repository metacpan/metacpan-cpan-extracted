
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "simple wrapper for google+ OAuth2 API",
  "AUTHOR" => "Matthijs van Henten <matthijs\@ischen.nl>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "FindBin" => 0,
    "Sub::Override" => 0,
    "Test::Class" => 0,
    "Test::More" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "OAuth2-Google-Plus",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "OAuth2::Google::Plus",
  "PREREQ_PM" => {
    "Carp::Assert" => 0,
    "JSON" => 0,
    "LWP::Protocol::https" => 0,
    "LWP::UserAgent" => 0,
    "Moo" => 0,
    "MooX::late" => 0,
    "URI" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
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



