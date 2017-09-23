

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SC::Lomonosov',
    VERSION_FROM => 'lib/SC/Lomonosov.pm', # finds \$VERSION
    AUTHOR       => 'Alexey Kulagin (alexfmsu@mail.ru)',
    ABSTRACT     => 'Creation client applications for ....',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
