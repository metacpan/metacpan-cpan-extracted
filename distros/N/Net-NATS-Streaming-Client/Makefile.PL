use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to NATS Streaming",
  "AUTHOR" => "Sergey Kolychev <sergeykolychev.github\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-NATS-Streaming-Client",
  "EXE_FILES" => [],
  "LICENSE" => "apache_2_0",
  "NAME" => "Net::NATS::Streaming::Client",
  "PREREQ_PM" => {
    "Net::NATS::Streaming::PB" => "0.03",
    "Net::NATS::Client" => "0.2.0",
    "UUID" => "0.05",
    "Class::XSAccessor" => "1.19"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
    "Net::NATS::Streaming::PB" => "0.03",
    "Net::NATS::Client" => "0.2.0",
    "UUID" => "0.05",
    "Class::XSAccessor" => "1.19"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



