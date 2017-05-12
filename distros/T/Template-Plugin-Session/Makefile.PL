use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'         => 'Template::Plugin::Session',
	'AUTHOR'       => 'Enrico Sorcinelli <enrico@sorcinelli.it>',
	'ABSTRACT'     => 'Template Toolkit interface to Apache::Session',
	'VERSION_FROM' => 'Session.pm', # finds $VERSION
	'PREREQ_PM'	   => {
		'Template' => 2.07,
		'Apache::Session' => 1.54
	}, 
   'clean'        => {FILES => 't/????????????????????????????????'},
);
