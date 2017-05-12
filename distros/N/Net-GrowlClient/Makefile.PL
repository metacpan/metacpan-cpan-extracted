use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::GrowlClient',
    VERSION_FROM      => 'lib/Net/GrowlClient.pm', 
    PREREQ_PM         => {
	    'Test::More' => 0,
        'Carp'    => 0,
        'IO::Socket'    => 0,
        'Exporter'    => 0,
		'Digest::MD5' => 0,
	  	'Digest::SHA' => 0
},
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Net/GrowlClient.pm',
       AUTHOR         => 'Raphaël ROULET <castor@cpan.org>') : ()),
);
