
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Install all the CPAN modules needed by Cabinet",
  "AUTHOR" => "Anton Gerasimov <chim\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.98",
    "Test::Pod" => "1.22"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-BeLike-CHIM-Cabinet",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::BeLike::CHIM::Cabinet",
  "PREREQ_PM" => {
    "Bundle::PlRPC" => 0,
    "Carp" => 0,
    "DBI" => 0,
    "Dancer" => "1.3100",
    "Dancer::Plugin::Database" => "2.04",
    "Dancer::Plugin::Redis" => "0.7",
    "Dancer::Session::Redis" => "0.21",
    "Digest::MurmurHash" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "Module::Versions" => 0,
    "Net::CIDR::Lite" => 0,
    "Plack" => 0,
    "Plack::Middleware::Debug" => 0,
    "Plack::Middleware::Debug::DBIProfile" => 0,
    "Plack::Middleware::Debug::Redis" => "0.02",
    "Starman" => 0,
    "Template::Plugin::Octets" => "0.18",
    "Text::MicroTemplate" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.15",
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



