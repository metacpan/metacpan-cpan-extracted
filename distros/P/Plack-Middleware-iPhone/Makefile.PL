
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Make your html more iPhone friendly',
  'AUTHOR' => 'Patrick Donelan <pat@patspam.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTML::Tidy' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Plack-Middleware-iPhone',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Plack::Middleware::iPhone',
  'PREREQ_PM' => {
    'Digest::MD5' => '0',
    'File::Slurp' => '0',
    'HTML::DOM' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util::Accessor' => '0',
    'UNIVERSAL::require' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.102060',
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



