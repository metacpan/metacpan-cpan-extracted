# use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    AUTHOR            => 'Philip Gwyn',
    NAME              => 'PostScript::PPD',
    VERSION_FROM      => 'lib/PostScript/PPD.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
        Compress::Zlib => 2,

    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PostScript/PPD.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <fil@localdomain>') : ()),
);
