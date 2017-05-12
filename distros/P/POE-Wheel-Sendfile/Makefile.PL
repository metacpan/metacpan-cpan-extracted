use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Wheel::Sendfile',
    VERSION_FROM      => 'lib/POE/Wheel/Sendfile.pm', # finds $VERSION
    PREREQ_PM         => {
            'POE'           => 1,
        }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Wheel/Sendfile.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <fil@localdomain>') : ()),
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},

);
