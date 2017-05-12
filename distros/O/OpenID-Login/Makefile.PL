
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A simple lightweight OpenID consumer with very few dependencies",
  "AUTHOR" => "Holger Eiboeck <realholgi\@cpan.org>",
  "BUILD_REQUIRES" => {
    "CGI" => 0,
    "Test::Mock::LWP::Dispatch" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "OpenID-Login",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "OpenID::Login",
  "PREREQ_PM" => {
    "Carp" => 0,
    "LWP::UserAgent" => 0,
    "List::MoreUtils" => 0,
    "Moose" => "0.51",
    "Moose::Util::TypeConstraints" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "strict" => 0
  },
  "VERSION" => "0.1.2",
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



