use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
exit 0 unless defined $ENV{R_HOME};
WriteMakefile(
    NAME              => 'Statistics::useR',
    VERSION_FROM      => 'lib/Statistics/useR.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Statistics/useR.pm', # retrieve abstract from module
       AUTHOR         => 'Xin Zheng <xinzheng@cpan.org>') : ()),
	LIBS              => ["-L$ENV{R_HOME}/lib -lR"], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => "-I. -I$ENV{R_HOME}/include", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
);
