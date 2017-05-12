use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Passwd::Unix',
    #($] >= 5.005 ? (   ## Add these new keywords supported since 5.005
#    (AUTHOR     => '£ukasz Strzelecki <strzelec@rswsystems.pl>') : ()),
	
    AUTHOR        => '£ukasz Strzelecki <strzelec@rswsystems.pl>',
    VERSION_FROM  => 'lib/Passwd/Unix.pm',
#    ABSTRACT_FROM => 'lib/Passwd/Unix.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Carp'						=> 0,
		'Crypt::PasswdMD5'			=> 1.3,
		'File::Spec'				=> 0,
		'File::Path'				=> 0,
		'File::Copy'				=> 0,
		'Struct::Compare'			=> 0,
		'File::Basename'			=> 0,
		'Exporter'					=> 0,
		'Config'					=> 0,
		'IO::Compress::Bzip2'		=> 2.015,
    },
	#) : ()),
);
