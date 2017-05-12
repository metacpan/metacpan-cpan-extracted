use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::ManageSieve',
    VERSION_FROM      => 'lib/Net/ManageSieve.pm', # finds $VERSION
    PREREQ_PM         => {
    	Socket => 1.3,
    	Carp => 0,			# minimal version?
    	IO::Socket => 0,		# minimal version?
    	Encode => 0,			# minimal version?
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/ManageSieve.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Kaiser <cpan@skaus.info>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    SIGN              => 1,
    LICENSE           => 'perl',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
