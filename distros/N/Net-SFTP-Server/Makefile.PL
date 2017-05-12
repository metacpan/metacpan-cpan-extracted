use 5.010000;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Net::SFTP::Server',
	       VERSION_FROM => 'lib/Net/SFTP/Server.pm',
	       PREREQ_PM => { 'File::Strmode' => 0.03,
			      ( $ENV{AUTOMATED_TESTING}
				? ('Net::SFTP::Foreign' => '1.52_07')
				: () )
			    },
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>' );

