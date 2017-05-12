
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Peek into the internals of a running POE environment",
  "AUTHOR" => "sungo <sungo\@sungo.us>, Yuval Kogman <nothingmuch\@woobling.org>, Chris 'BinGOs' Williams <bingos\@cpan.org>, Philip Gwyn <gwyn\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "POE-API-Peek",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "POE::API::Peek",
  "PREREQ_PM" => {
    "Devel::Size" => 0,
    "POE" => "1.311",
    "Test::More" => 0
  },
  "VERSION" => "2.20",
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



