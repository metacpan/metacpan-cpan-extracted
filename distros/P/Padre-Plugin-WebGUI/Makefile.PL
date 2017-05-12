
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'Developer tools for WebGUI',
  'AUTHOR' => 'Patrick Donelan <pdonelan@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Padre-Plugin-WebGUI',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Padre::Plugin::WebGUI',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Unload' => '0',
    'Class::XSAccessor' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Padre' => '0.69',
    'Padre::Current' => '0',
    'Padre::Document' => '0',
    'Padre::Locale' => '0',
    'Padre::Logger' => '0',
    'Padre::Plugin' => '0',
    'Padre::Util' => '0',
    'Padre::Wx' => '0',
    'utf8' => '0'
  },
  'VERSION' => '1.002',
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


