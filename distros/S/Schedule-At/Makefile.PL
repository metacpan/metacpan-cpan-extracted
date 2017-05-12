use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Schedule::At',
    'VERSION_FROM' => 'At.pm', # finds $VERSION
    'dist' => {
	TARFLAGS => 'cvf', 
	COMPRESS => 'gzip', 
	SUFFIX => 'gz',
	},
);
