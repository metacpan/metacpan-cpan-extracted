
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'DWIM syntax extensions',
  'AUTHOR' => 'Robert \'phaylon\' Sedlacek <rs@474.at>',
  'BUILD_REQUIRES' => {
    'Test::Fatal' => '0.003',
    'Test::More' => '0.98'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Syntax-Feature-Simple',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Syntax::Feature::Simple',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Sub::Install' => '0.925',
    'Syntax::Feature::Function' => '0.001',
    'Syntax::Feature::Method' => '0.001',
    'Syntax::Feature::Sugar::Callbacks' => '0.002',
    'parent' => '0',
    'strictures' => '1',
    'syntax' => '0.003'
  },
  'VERSION' => '0.002',
  'test' => {
    'TESTS' => 't/*.t'
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



