use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::BitCount',
    'VERSION_FROM'	=> 'BitCount.pm', # finds $VERSION
    ($] >= 5.005 ?	    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM	=> 'BitCount.pm', # retrieve abstract from module
       AUTHOR		=> 'Winfried Koenig <w.koenig@acm.org>') : ()),
);
