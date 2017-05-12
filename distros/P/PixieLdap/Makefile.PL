use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PixieLdap',
    VERSION_FROM      => 'lib/PixieLdap.pm', # finds $VERSION
    PREREQ_PM         => {
		'Net::LDAP'			=> 0,
		'Net::LDAPS'		=> 0,
		'Crypt::PasswdMD5'	=> 0,
		'YAML'				=> 0,

},
  dist => {
    COMPRESS => "gzip -9 -vf",
  },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PixieLdap.pm', # retrieve abstract from module
       AUTHOR         => 'Mark Olliver <mark@pixie79.org.uk>') : ()),
);
