
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "distributed locks via ZooKeeper",
  "AUTHOR" => "Yury Zavarin <yury.zavarin\@gmail.com>",
  "BUILD_REQUIRES" => {
    "IO::Handle" => 0,
    "POSIX" => 0,
    "Test::Class" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "parent" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-ZooKeeper-Lock",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::ZooKeeper::Lock",
  "PREREQ_PM" => {
    "Net::ZooKeeper" => 0,
    "Params::Validate" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
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



