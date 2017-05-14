
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'Catalyst helper interface for Padre',
  'AUTHOR' => 'Breno G. de Oliveira <garu@cpan.org>, Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
  'BUILD_REQUIRES' => {
    'Locale::Msgfmt' => '0.15',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Padre-Plugin-Catalyst',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Padre::Plugin::Catalyst',
  'PREREQ_PM' => {
    'Catalyst::Devel' => '1.0',
    'Catalyst::Runtime' => '5.70',
    'File::Which' => '0.05',
    'Padre' => '0.57'
  },
  'VERSION' => '0.13',
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

package
MY;
use File::ShareDir::Install qw(postamble);


