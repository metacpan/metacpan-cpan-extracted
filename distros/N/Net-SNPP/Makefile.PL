# This -*- perl -*- script makes the Makefile

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM  => 'lib/Net/SNPP.pm',
  NAME          => 'Net::SNPP',
  PREREQ_PM     => { 'Net::Cmd' => 0.01 },
);


