use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POSIX::strptime',
    VERSION_FROM      => 'lib/POSIX/strptime.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'  => 0,
        'XSLoader'    => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POSIX/strptime.pm', # retrieve abstract from module
       AUTHOR         => 'Philippe M. Chiasson <gozer@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    SIGN              => 1,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
