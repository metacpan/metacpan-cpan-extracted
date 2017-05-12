use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Roku::ECP',
    VERSION_FROM      => 'lib/Roku/ECP.pm', # finds $VERSION
    PREREQ_PM         => {
	    "Encode"		=> 0,
	    "URI"		=> 0,
	    "URI::Escape"	=> 0,
	    "LWP::UserAgent"	=> 0,
	    "FindBin"		=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Roku/ECP.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Arensburger <arensb+pause@ooblick.com>') : ()),
);
