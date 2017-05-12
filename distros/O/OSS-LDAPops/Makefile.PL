#makefile maker for UserMoveSelection


use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'		=>	'OSS::LDAPops',
	'VERSION_FROM'	=>	'lib/OSS/LDAPops.pm',
	'PREREQ_PM' => 
			{
				Net::LDAP	=> 0.34,

			},
	'EXE_FILES' =>
			[
				'bin/ldapops.pl',
				'bin/netgroupcache.pl'
			]
);
