
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a Reflex Stream object that can use POE::Filters",
  "AUTHOR" => "Nicholas R. Perez <nperez\@cpan.org>",
  "BUILD_REQUIRES" => {
    "POE::Filter::Line" => 0,
    "Socket" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Reflexive-Stream-Filtering",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Reflexive::Stream::Filtering",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Role" => 0,
    "POE::Filter::Stream" => 0,
    "Reflex::Event" => 0,
    "Reflex::Stream" => 0
  },
  "VERSION" => "1.122150",
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



