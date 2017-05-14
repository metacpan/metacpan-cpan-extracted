use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#The syntax of this makefile is copied from that of the MIME::Tools distribution.
WriteMakefile(
    	'NAME'	=> 'Storm-Tracker',
    	'VERSION_FROM' => 'lib/Geo/StormTracker.pm', # finds $VERSION
	'PREREQ_PM' => {
			'IO::Dir' => 1.03,
			'IO::File' => 1.08,
			'Time::Local' => 0,
			'File::Path' => 1.0401,
			},
	'dist'	=> {
		'PREOP' => q{(echo "hi jimmy";echo "isn't this fun";)},
		'COMPRESS' => 'gzip',
		'SUFFIX' => 'gz',
	},
);
