
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to the HTTP Rest API of the RabbitMQ management plugin",
  "AUTHOR" => "Ioana Budai <hurith\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Slurp" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-RabbitMQ-Management-API",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::RabbitMQ::Management::API",
  "PREREQ_PM" => {
    "HTTP::Message" => 0,
    "JSON" => 0,
    "JSON::Any" => 0,
    "LWP::UserAgent" => 0,
    "Moo" => 0,
    "URI" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t t/live/*.t"
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



