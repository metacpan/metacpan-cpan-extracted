
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a rudimentary Pure Perl AMQP client",
  "AUTHOR" => "Sam Crawley <mutant\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Class" => "0.37",
    "Test::MockObject" => "1.20120301"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Thumper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Thumper",
  "PREREQ_PM" => {
    "Moose" => "1.21",
    "Net::AMQP" => "0.04",
    "Try::Tiny" => "0.11"
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



