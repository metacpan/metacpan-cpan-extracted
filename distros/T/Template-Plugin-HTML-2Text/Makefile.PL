use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'Template::Plugin::HTML::2Text',
	VERSION_FROM	=> 'lib/Template/Plugin/HTML/2Text.pm',
	PREREQ_PM	=> {
		'Template'	=> '0',
		'HTML::FormatText::Html2text'	=> '19'
	},
	AUTHOR		=> 'Dalibor Horinek <dal@travelcook.com>',
);
