
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Provides IO::All',
  'AUTHOR' => 'Robert \'phaylon\' Sedlacek <rs@474.at>',
  'BUILD_REQUIRES' => {
    'Test::Fatal' => '0.003',
    'Test::More' => '0.96',
    'syntax' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Syntax-Feature-Io',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Syntax::Feature::Io',
  'PREREQ_PM' => {
    'B::Hooks::EndOfScope' => '0.09',
    'Carp' => '0',
    'IO::All' => '0.41',
    'Params::Classify' => '0.013',
    'Sub::Install' => '0.925',
    'namespace::clean' => '0',
    'strictures' => '1'
  },
  'VERSION' => '0.001',
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



