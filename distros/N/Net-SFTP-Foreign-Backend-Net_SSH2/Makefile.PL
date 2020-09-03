
use 5.008;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Net::SFTP::Foreign::Backend::Net_SSH2',
	       VERSION_FROM => 'lib/Net/SFTP/Foreign/Backend/Net_SSH2.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
	       PREREQ_PM => { 'Net::SSH2' => '0.62',
			      'Net::SFTP::Foreign' => '1.67' },
	       META_MERGE => { resources => { bugtracker => 'https://github.com/salva/p5-Net-SFTP-Foreign-Backend-Net_SSH2/issues',
					      repository => { type => 'git',
							      url => 'https://github.com/salva/p5-Net-SFTP-Foreign-Backend-Net_SSH2.git',
							      web => 'https://github.com/salva/p5-Net-SFTP-Foreign-Backend-Net_SSH2' } } } );
