use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'POE::Component::DebugShell::Jabber',
    AUTHOR => 'David Davis (xantus@cpan.org)',
    VERSION_FROM => 'lib/POE/Component/DebugShell/Jabber.pm',
    PREREQ_PM => {
        'POE' => '0.2601',
        'POE::API::Peek' => '0.02',
        'Test::More' => 0,
		'POE::Component::Jabber' => 0,
    },
	'dist'         => {
#        PREOP => 'svn log > ${DISTVNAME}/Changes',
		'SUFFIX'       => ".gz",
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => "gzip -9vf",
	},

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM	=> 'lib/POE/Component/DebugShell/Jabber.pm', # retrieve abstract from module
		 AUTHOR			=> 'David Davis <xantus@cpan.org>') : ()),

);

