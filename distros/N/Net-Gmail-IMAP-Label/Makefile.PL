
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "IMAP proxy for Google's Gmail that retrieves message labels",
  "AUTHOR" => "Zakariyya Mughal <zmughal\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Capture::Tiny" => "0.12",
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Gmail-IMAP-Label",
  "EXE_FILES" => [
    "bin/gmail-imap-label"
  ],
  "LICENSE" => "artistic_2",
  "NAME" => "Net::Gmail::IMAP::Label",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Encode" => 0,
    "Encode::IMAPUTF7" => 0,
    "FindBin" => 0,
    "Getopt::Long::Descriptive" => 0,
    "POE" => 0,
    "POE::Component::Client::TCP" => 0,
    "POE::Component::SSLify" => 0,
    "POE::Component::Server::TCP" => 0,
    "POE::Filter::Map" => 0,
    "POE::Filter::Stackable" => 0,
    "Regexp::Common" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.007",
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



