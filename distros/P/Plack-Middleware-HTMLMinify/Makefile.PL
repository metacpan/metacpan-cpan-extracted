
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Plack middleware to minify HTML on-the-fly',
  'AUTHOR' => 'Gea-Suan Lin <gslin@gslin.org>',
  'BUILD_REQUIRES' => {
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
  'DISTNAME' => 'Plack-Middleware-HTMLMinify',
  'EXE_FILES' => [],
  'LICENSE' => 'bsd',
  'NAME' => 'Plack::Middleware::HTMLMinify',
  'PREREQ_PM' => {
    'HTML::Packer' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.0.0',
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



