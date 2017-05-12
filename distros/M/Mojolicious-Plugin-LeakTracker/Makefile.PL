
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Helps you track down memory leaks in your code",
  "AUTHOR" => "Ben van Staveren <madcat\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mojolicious-Plugin-LeakTracker",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojolicious::Plugin::LeakTracker",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Devel::Cycle" => 0,
    "Devel::Events::Filter::RemoveFields" => 0,
    "Devel::Events::Filter::Stamp" => 0,
    "Devel::Events::Filter::Stringify" => 0,
    "Devel::Events::Generator::Objects" => 0,
    "Devel::Events::Handler::Log::Memory" => 0,
    "Devel::Events::Handler::Multiplex" => 0,
    "Devel::Events::Handler::ObjectTracker" => 0,
    "Devel::Size" => 0,
    "Mojo::Base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.00",
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



