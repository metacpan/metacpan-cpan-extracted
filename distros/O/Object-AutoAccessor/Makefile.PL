use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'			=> 'Object::AutoAccessor',
	'VERSION_FROM'	=> 'lib/Object/AutoAccessor.pm', # finds $VERSION
	'PREREQ_PM'		=> {
		Test::More => 0.32
	},
);
