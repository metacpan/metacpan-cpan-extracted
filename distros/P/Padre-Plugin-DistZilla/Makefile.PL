
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A plugin for Padre to create modules with Dist::Zilla',
  'AUTHOR' => 'Renee Baecker <module@renee-baecker.de>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Padre-Plugin-DistZilla',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Padre::Plugin::DistZilla',
  'PREREQ_PM' => {
    'Dist::Zilla' => '4.102340',
    'File::Which' => '1.09',
    'Padre' => '0.70',
    'Try::Tiny' => '0.06',
    'Wx::Perl::DirTree' => '0.07'
  },
  'VERSION' => '0.02',
  'test' => {
    'TESTS' => ''
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



