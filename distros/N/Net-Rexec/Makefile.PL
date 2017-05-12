use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Rexec',
    'VERSION_FROM' => 'Rexec.pm', # finds $VERSION
    'PREREQ_PM' => { 'IO::Socket' => 0,
                     'Net::Netrc' => 0,
		   },
    'dist'	=> { 'COMPRESS' => 'gzip',
    		     'SUFFIX'	=> '.gz',
		   },
);
