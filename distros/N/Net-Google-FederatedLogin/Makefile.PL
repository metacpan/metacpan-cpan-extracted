
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Google Federated Login module - see http://code.google.com/apis/accounts/docs/OpenID.html",
  "AUTHOR" => "Glenn Fowler <cebjyre\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Google-FederatedLogin",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Google::FederatedLogin",
  "PREREQ_PM" => {
    "Carp" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => "0.51",
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "URI::Escape" => 0,
    "XML::Twig" => 0
  },
  "TEST_REQUIRES" => {
    "CGI" => 0,
    "Test::Mock::LWP" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.8.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



