use warnings FATAL => 'all';
use strict;

use 5.008007;
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mozilla::nsID',
    VERSION_FROM      => 'lib/Mozilla/nsID.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mozilla/nsID.pm', # retrieve abstract from module
       AUTHOR         => 'Boris Sukholitko <boris@>') : ()),
    LIBS              => ['-L/usr/lib/mozilla -lxpcom -lplds4 -lplc4 -lnspr4 -ldl -lc -lpthread'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CC            => 'g++',
    INC               => '-I. -I/usr/include/mozilla -I/usr/include/mozilla/nspr',
    LD            => "LD_RUN_PATH=/usr/lib/mozilla $Config{ld}",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
