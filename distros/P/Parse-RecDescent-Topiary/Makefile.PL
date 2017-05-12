

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Parse::RecDescent::Topiary',
    VERSION_FROM => 'lib/Parse/RecDescent/Topiary.pm', # finds \$VERSION
    AUTHOR       => 'Ivor Williams (ivorw@cpan.org)',
    ABSTRACT     => 'tree surgery for Parse::RecDescent autotrees',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Parse::RecDescent' => 0,
		     'Module::Optional' => 0,
		     'Scalar::Util' => 0,
                    },
    LICENSE	 => 'perl',
);
