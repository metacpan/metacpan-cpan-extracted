

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Proc::ProcessTableLight',
    VERSION_FROM => 'lib/Proc/ProcessTableLight.pm', # finds \$VERSION
    AUTHOR       => 'Evgeniy Bulichev (bes@cpan.org)',
    ABSTRACT     => 'Create simple process table',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
