# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A base class to make your very own Telegram bot",
  "AUTHOR" => "Justin Hawkins <justin\@eatmorecode.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Telegram-Bot",
  "LICENSE" => "perl",
  "NAME" => "Telegram::Bot",
  "PREREQ_PM" => {
    "IO::Socket::SSL" => "2.037",
    "Log::Any" => "1.032",
    "Mojolicious" => "8.00",
    "Test::Exception" => "0.43"
  },
  "VERSION" => "0.021",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "IO::Socket::SSL" => "2.037",
  "Log::Any" => "1.032",
  "Mojolicious" => "8.00",
  "Test::Exception" => "0.43"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
