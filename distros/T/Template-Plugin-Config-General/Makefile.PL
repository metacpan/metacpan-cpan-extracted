use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Template::Plugin::Config::General',
    VERSION_FROM	=> 'lib/Template/Plugin/Config/General.pm', # finds $VERSION
    PREREQ_PM		=> {
	'Template'		=> '0',
	'Config::General'	=> '0',
    }, # e.g., Module::Name => 1.1
    AUTHOR		=> 'Igor Lobanov <liol@cpan.org>',
);
