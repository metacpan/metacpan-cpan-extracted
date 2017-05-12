use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.006001;

do "mkheader";

WriteMakefile(
    'NAME'		=> 'ShiftJIS::X0213::MapUTF',
    'VERSION_FROM'	=> 'MapUTF.pm',
    'ABSTRACT_FROM'	=> 'MapUTF.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> {FILES=> 'fmsj0213.h tosj0213.h'},
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	Carp		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	vars		=> 0,
    },
);
