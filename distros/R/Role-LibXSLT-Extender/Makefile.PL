
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Moose Role to simplify creating/registering Perl extension functions for LibXSLT",
  "AUTHOR" => "Kip Hampton <khampton\@totalcinema.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Role-LibXSLT-Extender",
  "EXE_FILES" => [
    "bin/xxslt.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Role::LibXSLT::Extender",
  "PREREQ_PM" => {
    "Moose" => 0,
    "XML::LibXSLT" => "1.70",
    "namespace::autoclean" => 0
  },
  "VERSION" => "1.140260",
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



