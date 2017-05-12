

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SwitchMac',
    VERSION_FROM => 'lib/SwitchMac.pm', # finds \$VERSION
    AUTHOR       => 'Rafael Lucas (rafalucas@cpan.org)',
    ABSTRACT     => 'provide tools to change the mac address',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
