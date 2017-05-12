#use 5.008003;
use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SWISH::API::Remote',
    VERSION_FROM      => 'lib/SWISH/API/Remote.pm', # finds $VERSION
    PREREQ_PM         => {   # e.g., Module::Name => 1.1
			URI::Escape => 0,
			LWP::UserAgent => 0,
			}, 
	#EXE_FILES		=> [ 'example/swishedsearch' ],	# this will get installed in, ie, /usr/bin
	# don't install any exes
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISH/API/Remote.pm', # retrieve abstract from module
       AUTHOR         => 'joshr <joshr.com>') : ()),
);
