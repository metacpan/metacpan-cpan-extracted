
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Signs requests using Amazon's Signature Version 4.",
  "AUTHOR" => "Charles A. Wimmer <charles\@wimmer.net>",
  "BUILD_REQUIRES" => {
    "Dist::Zilla::App::Command::cover" => 0,
    "File::Slurp" => 0,
    "HTTP::Request" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "List::Compare" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "TAP::Formatter::JUnit" => 0,
    "TAP::Harness::JUnit" => 0,
    "Test::More" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Amazon-SignatureVersion4",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "Net::Amazon::SignatureVersion4",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Digest::SHA" => 0,
    "HTTP::Date" => 0,
    "MooseX::App" => 0,
    "POSIX" => 0,
    "URI::Encode" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.006",
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



