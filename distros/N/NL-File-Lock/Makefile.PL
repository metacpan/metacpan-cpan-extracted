use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME' => 'NL::File::Lock',
	'VERSION_FROM' => 'lib/NL/File/Lock.pm', # finds $VERSION
	'PREREQ_PM' => {}, # e.g., Module::Name => 1.1
	($] >= 5.005 ? (
			## Add these new keywords supported since 5.005
			ABSTRACT => 'File locking (based on lockfiles)',
			AUTHOR   => 'Nickolay Kovalev, http://resume.nickola.ru'
			) : ()
	),
);
