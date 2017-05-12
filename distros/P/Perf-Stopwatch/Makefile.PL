use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Perf::Stopwatch',
    'VERSION_FROM'	=> 'Stopwatch.pm',
    'PREREQ_PM'		=> {
         'Time::HiRes' => undef 
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Stopwatch.pm',
       AUTHOR     => 'Kit DeKat <kitdekat@kitdekat.com>') : ()),
);
