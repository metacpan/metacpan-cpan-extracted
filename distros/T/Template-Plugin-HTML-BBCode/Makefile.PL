use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'Template::Plugin::HTML::BBCode',
	VERSION_FROM	=> 'lib/Template/Plugin/HTML/BBCode.pm',
	PREREQ_PM	=> {
		'Template'	=> '0',
		'HTML::BBCode'	=> '1.01'
	},
	AUTHOR		=> 'Igor Lobanov <liol@cpan.org>',
);
