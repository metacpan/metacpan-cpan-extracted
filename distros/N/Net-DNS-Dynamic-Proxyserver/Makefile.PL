use ExtUtils::MakeMaker;

WriteMakefile(

        NAME            => 'Net::DNS::Dynamic::Proxyserver',
        VERSION_FROM    => 'lib/Net/DNS/Dynamic/Proxyserver.pm',

        AUTHOR           => 'Marc Sebastian Jakobs',
        ABSTRACT         => 'A dynamic DNS proxy server.',

		INST_SCRIPT		=> 'script/',
		INSTALLSCRIPT	=> '/usr/local/bin',

   'PREREQ_PM' => {
		'POSIX'				=> 1.13,
		'Carp'				=> 1.08,
		'Perl6::Junction'	=> 1.40000,
		'Net::DNS'			=> 0.65,
		'Net::DNS::Nameserver'	=> 749,
		'Moose'				=> 0.92,
		'Moose::Util::TypeConstraints' => 0.92,
		'DBI'				=> 1.601,
    }
);
