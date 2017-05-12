use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'		=> 'POE::Component::NomadJukebox::Device',
	'VERSION_FROM'	=> 'Device.pm',
	'PREREQ_PM'		=> {
		# module => '1.01',
	},
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(
			# ABSTRACT_FROM => 'Device.pm', # retrieve abstract from module
			AUTHOR     => 'David Davis <xantus@cpan.org>') : ()),
			'LIBS'		=> ['-lnjb -lusb'],
			'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
			# Insert -I. if you add *.h files later:
#			'INC'		=> '-I/usr/include/', # e.g., '-I/usr/include/other'
			# Un-comment this if you add C files to link with later:
			'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
