use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME             => 'PPI::Transform::Doxygen',
  VERSION_FROM     => 'lib/PPI/Transform/Doxygen.pm',
  ABSTRACT         => 'Transform POD documentation to doxygen compatible format',
  AUTHOR           => 'Thomas Kratz <tomk@cpan.org>',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.010001, 
  EXE_FILES        => ['bin/ppi_transform_doxygen'],
  PREREQ_PM        =>  {
    'PPI' => '1.220',
    'Pod::POM' => '2.01',
  },

  TEST_REQUIRES    => {
  },

  BUILD_REQUIRES   => {
  },

  META_MERGE       => {
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/tomk3003/ppi-transform-doxygen',
      bugtracker  => 'https://github.com/tomk3003/ppi-transform-doxygen/issues'
    },
    no_index => {directory => ['t']}
  },

  test             => {TESTS => 't/*.t'}
);
