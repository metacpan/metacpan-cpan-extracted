require 5.8.4;

use ExtUtils::MakeMaker;

WriteMakefile(
  'PL_FILES' => {},
	'NAME'            => 'SQL::Loader',
 	'INSTALLDIRS' 		=> 'site',
  'VERSION_FROM'    => 'lib/SQL/Loader.pm',
 	'PREREQ_PM'				=> {
										 	'Test::More' => '0',
											'Test::Exception' => '0',
											'LWP::Simple'	=> '0',
											'Getopt::Long'	=> '0',
											'DBI'	=> '0'
	}
);

