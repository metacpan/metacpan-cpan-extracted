# -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME		=> 'ShellScript-Env',
   VERSION	=> '0.5',
   dist		=> { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
  );

