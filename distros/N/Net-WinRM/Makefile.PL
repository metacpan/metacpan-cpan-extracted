use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Net::WinRM',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'WinRM.pm',
	VERSION_FROM  => 'WinRM.pm',
	EXE_FILES     => ['winrm'],
	PREREQ_PM     => {
		'Data::UUID'        => 0,
		'XML::Simple'       => 0,
		'LWP'               => 0,
		'IO::Lambda'        => 0.25,
		'Authen::NTLM'      => 1.05,
	},
);
