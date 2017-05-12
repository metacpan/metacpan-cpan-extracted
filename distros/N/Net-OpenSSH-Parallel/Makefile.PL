use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Net::OpenSSH::Parallel',
	       VERSION_FROM => 'lib/Net/OpenSSH/Parallel.pm',
	       PREREQ_PM => { 'Net::OpenSSH' => '0.60' },
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
	       META_MERGE => {
	           'meta-spec' => { version => 2 },
	           resources => {
	               repository => {
	                   type => 'git',
	                   url  => 'https://github.com/salva/p5-Net-OpenSSH-Parallel.git',
	                   web  => 'https://github.com/salva/p5-Net-OpenSSH-Parallel',
	               },
	           },
	       },
);
