
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'PSGI/Plack plugin for Padre',
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
  'DISTNAME' => 'Padre-Plugin-Plack',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Padre::Plugin::Plack',
  'PREREQ_PM' => {
    'Class::Unload' => '0',
    'Class::XSAccessor' => '0',
    'File::Basename' => '0',
    'File::Find::Rule' => '0',
    'File::Which' => '0',
    'Padre' => '0.60',
    'Padre::Current' => '0',
    'Padre::Document::Perl' => '0',
    'Padre::Logger' => '0',
    'Padre::MimeTypes' => '0',
    'Padre::Plugin' => '0',
    'Padre::Util' => '0',
    'Padre::Wx' => '0',
    'Padre::Wx::Output' => '0',
    'Plack' => '0.9021',
    'Proc::Killfam' => '0',
    'Scalar::Util' => '0',
    'Wx' => '0',
    'Wx::Perl::ProcessStream' => '0',
    'utf8' => '0'
  },
  'VERSION' => '1.200',
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


