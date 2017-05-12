
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'include/run examples scripts in your documentation without copy/paste',
  'AUTHOR' => 'FOOLISH <FOOLISH@cpan.org>',
  'BUILD_REQUIRES' => {
    'Pod::Elemental' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Pod-Elemental-Transformer-ExampleRunner',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Pod::Elemental::Transformer::ExampleRunner',
  'PREREQ_PM' => {
    'Data::Dumper' => '0',
    'Moose' => '0',
    'Pod::Elemental::Element::Pod5::Command' => '0',
    'Pod::Elemental::Transformer' => '0.101620',
    'Pod::Elemental::Types' => '0',
    'namespace::autoclean' => '0'
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



