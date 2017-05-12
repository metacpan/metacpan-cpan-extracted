
use strict;
use warnings;

BEGIN { require v5.010.1; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A templating engine using the L<JavaScript::V8> module',
  'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Slurp' => '0',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Test::More' => '0',
    'Test::Output' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Template-JavaScript',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Template::JavaScript',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'JavaScript::V8' => '0',
    'JavaScript::Value::Escape' => '0',
    'Template' => '0'
  },
  'VERSION' => '0.01',
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



