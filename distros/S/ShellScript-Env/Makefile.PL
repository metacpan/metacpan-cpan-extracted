# -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME		=> 'ShellScript-Env',
   VERSION	=> '0.4',
   dist		=> { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
  );

