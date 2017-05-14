
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Install all the modules from PJF's talk at OSDC 2012",
  "AUTHOR" => "Paul Fenwick <pjf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-OSDC2012",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::OSDC2012",
  "PREREQ_PM" => {
    "App::cpanminus" => 0,
    "Dancer" => 0,
    "Dist::Zilla" => 0,
    "Moose" => 0,
    "MooseX::Declare" => 0,
    "MooseX::Method::Signatures" => 0,
    "Perl::Critic" => 0,
    "Plack" => 0,
    "Regexp::Debugger" => 0,
    "autodie" => 0,
    "local::lib" => 0
  },
  "VERSION" => "0.001",
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



