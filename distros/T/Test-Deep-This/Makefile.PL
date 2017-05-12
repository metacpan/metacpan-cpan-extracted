
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Test::Deep extension to check predicates on plain scalars',
  'AUTHOR' => 'Andrei Mischhcenko <me@druxa.ru>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'Test::Tester' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Test-Deep-This',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Test::Deep::This',
  'PREREQ_PM' => {
    'Data::Dumper' => '0',
    'Exporter' => '0',
    'Test::Deep' => '0',
    'Test::Deep::Cmp' => '0',
    'overload' => '0'
  },
  'VERSION' => '1.00',
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



