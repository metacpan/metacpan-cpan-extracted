use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Net::Finger',
    'VERSION_FROM' => 'Finger.pm', # finds $VERSION
	'dist' => { 'COMPRESS' => 'gzip --best' },
);
