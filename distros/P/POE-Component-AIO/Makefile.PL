use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'			=> 'POE::Component::AIO',
    'VERSION_FROM'	=> 'AIO.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Carp'      => undef,
        'IO::AIO'   => undef,
        'POE'       => undef,
    },
	'dist'         => {
		'SUFFIX'       => ".gz",
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => "gzip -9vf",
	},
);
