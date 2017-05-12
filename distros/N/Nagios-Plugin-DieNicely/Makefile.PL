

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Nagios::Plugin::DieNicely',
    VERSION_FROM => 'lib/Nagios/Plugin/DieNicely.pm', # finds \$VERSION
    AUTHOR       => 'Jose Luis Martinez (jlmartinez@capside.com)',
    ABSTRACT     => 'Die in a Nagios compatible fashion',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Test::More'   => 0.62,
                    },
    LICENSE      => 'perl'
);
