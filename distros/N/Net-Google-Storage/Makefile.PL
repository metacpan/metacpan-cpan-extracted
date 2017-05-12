
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Access the Google Storage JSON API (currently experimental).",
  "AUTHOR" => "Glenn Fowler <cebjyre\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Digest::MD5" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Google-Storage",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Google::Storage",
  "PREREQ_PM" => {
    "HTTP::Status" => 0,
    "JSON" => 0,
    "LWP::MediaTypes" => 0,
    "LWP::UserAgent" => "6.04",
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "URI::Escape" => "3.29",
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
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



