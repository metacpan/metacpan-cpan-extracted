use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile( NAME              => 'Net::LDAP::Gateway',
	       VERSION_FROM      => 'lib/Net/LDAP/Gateway.pm',
	       PREREQ_PM         => {},
	       AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>',
	       LIBS              => [''],
	       DEFINE            => '',
	       INC               => '-I.',
	       OPTIMIZE => '-O0 -g',
	       OBJECT            => '$(O_FILES)' );
