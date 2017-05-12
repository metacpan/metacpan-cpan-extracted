use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::uFTP',
    #($] >= 5.005 ? (   ## Add these new keywords supported since 5.005
#    (AUTHOR     => '£ukasz Strzelecki <strzelec@rswsystems.pl>') : ()),
	
    AUTHOR        => '£ukasz Strzelecki <strzelec@rswsystems.pl>',
    VERSION_FROM  => 'lib/Net/uFTP.pm',
    ABSTRACT_FROM => 'lib/Net/uFTP.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'UNIVERSAL::require'		=> 0,
        'Carp'						=> 0,
        'Net::FTP'					=> 0,
        'Net::FTP::AutoReconnect'	=> 0,
		'Net::SSH2'					=> 0,
		'File::Stat::ModeString'	=> 0,
		'Class::Accessor::Fast::XS'	=> 0,
    },
	#) : ()),
);
