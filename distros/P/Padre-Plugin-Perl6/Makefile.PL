
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl 6 Support for Padre',
  'AUTHOR' => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>, Gabor Szabo L<http://szabgab.com/>',
  'BUILD_REQUIRES' => {
    'Locale::Msgfmt' => '0.15',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Padre-Plugin-Perl6',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Padre::Plugin::Perl6',
  'PREREQ_PM' => {
    'App::Grok' => '0.22',
    'Class::XSAccessor' => '1.02',
    'File::Which' => '0.05',
    'Padre' => '0.76',
    'Perl6::Doc' => '0.45',
    'Syntax::Highlight::Perl6' => '0.87',
    'URI' => '1.37'
  },
  'VERSION' => '0.71',
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


