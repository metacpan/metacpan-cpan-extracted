use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sparse',
    'VERSION_FROM'	=> 'Sparse.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Sparse.pm', # retrieve abstract from module
       AUTHOR     => 'Amruta D Purandare <pura0010@d.umn.edu>, Ted Pedersen <tpederse@d.umn.edu>') : ()),
);
