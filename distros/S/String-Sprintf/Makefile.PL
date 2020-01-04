

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'String::Sprintf',
    VERSION_FROM => 'lib/String/Sprintf.pm', # finds \$VERSION
    AUTHOR       => 'Bart Lateur (bart.lateur@pandora.be)',
    ABSTRACT     => 'Custom overloading of sprintf',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/briandfoy/string-sprintf.git',
                web  => 'https://github.com/briandfoy/string-sprintf',
            },
        }})
     : ()
    ),
);
