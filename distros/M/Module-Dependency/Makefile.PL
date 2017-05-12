use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR	=> 'Tim Bunce (timb@cpan.org)', # orginal author P Kent (PKENT)
    ABSTRACT	=> 'Parse, store, and report on dependencies between perl files',
    NAME	=> 'Module::Dependency',
    DISTNAME	=> 'Module-Dependency',
    dist  => {
        DIST_DEFAULT=> 'clean distcheck disttest tardist',
        PREOP => '$(MAKE) -f Makefile.old distdir',
        COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
    VERSION 	=> '1.86',
    PREREQ_PM	=> {
        Storable => 0,
        File::Find => 0,
        File::Spec => 0,
    },
    EXE_FILES	=> [ qw(pmd_dump.pl  pmd_grapher.plx  pmd_indexer.plx) ],
);
