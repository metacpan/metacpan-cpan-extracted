require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Switch::Perlish',
  VERSION_FROM => 'lib/Switch/Perlish.pm',
  AUTHOR       => 'Dan Brook',
  PREREQ_PM   => {
    'Scalar::Util' => 1.01,
  },
);
