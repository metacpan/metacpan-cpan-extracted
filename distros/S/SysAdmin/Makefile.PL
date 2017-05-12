
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SysAdmin',
    VERSION_FROM      => 'lib/SysAdmin.pm', # finds $VERSION
    PREREQ_PM => {
    	'DBI' => '',
	'MIME::Lite' => '',
	'Net::SMTP' => '',
	'Expect' => '',
	'Net::SNMP' => '',
	'IO::File' => '',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SysAdmin.pm', # retrieve abstract from module
       AUTHOR         => 'Miguel A. Rivera <marr@cpan.org>') : ()),
);
