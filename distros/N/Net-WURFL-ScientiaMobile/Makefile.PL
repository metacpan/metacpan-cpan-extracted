
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Client for the ScientiaMobile cloud webservice",
  "AUTHOR" => "Alessandro Ranellucci <aar\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-WURFL-ScientiaMobile",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::WURFL::ScientiaMobile",
  "PREREQ_PM" => {
    "Digest::MD5" => 0,
    "Exception::Class" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "Module::Load" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Plack::Request" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "constant" => 0
  },
  "VERSION" => "1.0.3",
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



