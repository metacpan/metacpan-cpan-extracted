
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "The Illicit Love Child of Moose and POE",
  "AUTHOR" => "Chris Prather <chris\@prather.org>, Ash Berlin <ash\@cpan.org>, Chris Williams <chris\@bingosnet.co.uk>, Yuval (nothingmuch) Kogman, Torsten Raudssus <torsten\@raudssus.de> L<http://www.raudssus.de/>",
  "BUILD_REQUIRES" => {
    "Test::Fatal" => "0.003",
    "Test::More" => "0.90"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MooseX-POE",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MooseX::POE",
  "PREREQ_PM" => {
    "Moose" => "2.0002",
    "POE" => "1.310"
  },
  "VERSION" => "0.215",
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



