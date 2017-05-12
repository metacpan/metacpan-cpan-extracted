
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Access isohunt.com from Perl',
  'AUTHOR' => 'Alan Haggai Alavi <alanhaggai@alanhaggai.org>',
  'BUILD_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Net-isoHunt',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::isoHunt',
  'PREREQ_PM' => {
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'URI' => '0'
  },
  'VERSION' => '0.102770',
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



