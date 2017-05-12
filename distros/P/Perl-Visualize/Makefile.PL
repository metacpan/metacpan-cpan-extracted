use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Perl::Visualize',
    'VERSION_FROM'	=> 'Visualize.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Generate Perl/GIF polyglots', # retrieve abstract from module
       AUTHOR     => 'Jasvir Nagra <jas@cs.auckland.ac.nz>') : ()),
);
