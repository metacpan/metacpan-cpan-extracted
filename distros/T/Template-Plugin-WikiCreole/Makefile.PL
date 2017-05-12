
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Template::Plugin::WikiCreole',
    VERSION_FROM => 'lib/Template/Plugin/WikiCreole.pm', # finds \$VERSION
    AUTHOR       => 'Martin Ellis (@cpan.org)',
    ABSTRACT     => 'TT wrapper for Text::WikiCreole',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Template'	    => 2,
		     'Text::WikiCreole' => 0.07,
		     'Template::Plugin::Filter' => 0,
		     'Template::Test' => 0,
                    },
    LICENSE	 => 'perl',
);
