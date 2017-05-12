

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Template::Plugin::LLHash',
    VERSION_FROM => 'lib/Template/Plugin/LLHash.pm', # finds \$VERSION
    AUTHOR       => 'Kevin C. McGrath (kmcgrath@baknet.com)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Template::Plugin' => 0,
                     'Tie::LLHash'      => 1.003,
                     'Test::Simple'     => 0.44,
                    },
);
