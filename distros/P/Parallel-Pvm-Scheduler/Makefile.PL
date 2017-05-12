use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Parallel::Pvm::Scheduler',
    'VERSION_FROM'	=> 'Scheduler.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Parallel::Pvm' => 1.4.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Scheduler.pm', # retrieve abstract from module
       AUTHOR     => 'Ryan Golhar <golharam@umdnj.edu>') : ()),
);
