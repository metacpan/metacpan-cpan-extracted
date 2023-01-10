use ExtUtils::MakeMaker::CPANfile;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Promise-ES6.git',
                web => 'https://github.com/FGasper/p5-Promise-ES6',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Promise-ES6/issues',
            },
        },
    },

    NAME         => 'Promise::ES6',
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    VERSION_FROM => 'lib/Promise/ES6.pm',         # finds \$VERSION
    ABSTRACT_FROM => 'lib/Promise/ES6.pm',
    LICENSE      => 'perl_5',
);
