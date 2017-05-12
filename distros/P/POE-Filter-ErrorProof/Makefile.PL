use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Filter::ErrorProof',
    VERSION_FROM      => 'lib/POE/Filter/ErrorProof.pm', # finds $VERSION
    			# we basically allow any version of POE, as long as it has POE::Filter::Stream.
    PREREQ_PM         => {POE => 0.1000}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/POE/Filter/ErrorProof.pm', # retrieve abstract from module
       AUTHOR         => 'Sjors Gielen <sjorsgielen@gmail.com>') : ()),
);
