use ExtUtils::MakeMaker;

use File::Copy ();

if ($] < 5.0060009 and -f "MapUTF.xs") {
    do "disableXS";
}

my $clean = {};

if (-f "MapUTF.xs") {
    print STDERR "Making header files for XSUB...\n";
    do "mkheader";
    $clean = {FILES=> 'fmcp932.h tocp932.h'};
}

WriteMakefile(
    'NAME'		=> 'ShiftJIS::CP932::MapUTF',
    'VERSION_FROM'	=> 'MapUTF.pm',
    'ABSTRACT_FROM'	=> 'MapUTF.pod',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> $clean,
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	Carp		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	File::Copy	=> 0,
	strict		=> 0,
	vars		=> 0,
    },
);

