use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Pod::BBCode',
    VERSION_FROM      => 'lib/Pod/BBCode.pm', # finds $VERSION
    PREREQ_PM         => {
        'Pod::Parser'   => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (
        EXE_FILES      => [ 'bin/pod2bbcode' ],
        ABSTRACT_FROM  => 'lib/Pod/BBCode.pm', # retrieve abstract from module
        AUTHOR         => 'chaoslawful <chaoslaw@cpan.org>'
        ) : ()),
);
