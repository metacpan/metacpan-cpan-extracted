use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Perf::ARM',
    'VERSION_FROM' => 'ARM.pm', # finds $VERSION
    'LIBS'	=> ['-larm'],   # e.g., '-lm'
    'INC'	=> '',

    # uncomment the following line to enable debug compilation
    # OPTIMIZE	=> '-g',

    'dist' => {
	# use gzip, not compress, and force over existing
	'COMPRESS'  => "gzip -f",
    },
);
