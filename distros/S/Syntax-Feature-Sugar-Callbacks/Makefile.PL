
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Add sugar for declarative method callbacks',
  'AUTHOR' => 'Robert \'phaylon\' Sedlacek <rs@474.at>',
  'BUILD_REQUIRES' => {
    'Test::Fatal' => '0.003',
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Syntax-Feature-Sugar-Callbacks',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Syntax::Feature::Sugar::Callbacks',
  'PREREQ_PM' => {
    'B::Hooks::EndOfScope' => '0.09',
    'Carp' => '0',
    'Data::Dump' => '0',
    'Devel::Declare' => '0.006000',
    'Params::Classify' => '0.011',
    'aliased' => '0',
    'namespace::clean' => '0.18',
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



