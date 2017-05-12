# This -*- perl -*- script makes the Makefile

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM  => 'PH.pm',
  NAME          => 'Net::PH',
  PREREQ_PM     => { 'Net::Cmd' => 0.01 },
);


