use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::Highlight',
    VERSION_FROM      => 'hl', # finds $VERSION
    EXE_FILES         => [ 'hl' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Highlight.pm', # retrieve abstract from module
       AUTHOR         => 'A. Radkov <alexey.radkov@gmail.com>') : ()),
);
