
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::WAMP',
    VERSION_FROM => 'lib/Net/WAMP.pm',         # finds \$VERSION
    AUTHOR       => 'Felipe Gasper',
    ABSTRACT_FROM => 'lib/Net/WAMP.pm',
    LICENSE      => 'perl',

    #Bleh. Hopefully can improve.
    MIN_PERL_VERSION => 5.014000,

    PREREQ_PM    => {
        'autodie'                  => 0,
        'parent'                   => 0,
        'X::Tiny'                  => 0.02,
        'Module::Load'  => 0,
        'Try::Tiny' => 0,
        'Types::Serialiser' => 0,

        #recommend JSON
        #recommend IO::Framed 0.02+

    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Net-WAMP.git',
                web  => 'https://github.com/FGasper/p5-Net-WAMP',
            },
        },
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
        'Test::Simple'    => 0,
        'Test::Deep' => 0,
        'File::Temp' => 0,
        'File::Slurp' => 0,
        'JSON' => 0,
        'Hash::Merge' => 0,
    },
);
