
use 5.008;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Net::SFTP::Foreign::Backend::Net_SSH2',
	       VERSION_FROM => 'lib/Net/SFTP/Foreign/Backend/Net_SSH2.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
	       PREREQ_PM => { 'Net::SSH2' => '0.38',
			      'Net::SFTP::Foreign' => '1.67' },

);
