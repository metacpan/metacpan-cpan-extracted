use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Net::SSH::Perl::ProxiedIPC',
	'ABSTRACT'     => 'Make long distance SSH commands',
	'VERSION_FROM' => 'lib/Net/SSH/Perl/ProxiedIPC.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'Jennie Rose Evers-Corvina <seven@nanabox.net>',
	
	'META_MERGE'     => {
		license => 'perl',
		resources => {
			repository  => 'https://github.com/briandfoy/Net-SSH-Perl-ProxiedIPC',
		  },
		},

	'PREREQ_PM'    => { 
		'IPC::PerlSSH'   => '0',
		'Net::SSH::Perl' => '0',
		},

	clean  => { FILES    => q|Net-SSH-Perl-ProxiedIPC-*| },
	);
