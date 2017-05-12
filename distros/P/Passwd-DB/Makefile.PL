use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Passwd::DB',
    'VERSION_FROM' => 'DB.pm', # finds $VERSION
	'PREREQ_PM' => {'DB_File' => 0}

);
