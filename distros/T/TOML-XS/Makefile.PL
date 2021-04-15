use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'TOML::XS',
    VERSION_FROM      => 'lib/TOML/XS.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/TOML/XS.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LIBS              => ['-ltoml'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-Wall --std=c99 -I.', # e.g., '-I. -I/usr/include/other'
    LICENSE           => "perl_5",

    OBJECT => [
        '$(BASEEXT)$(OBJ_EXT)',
        'toml.o',
        'tomlxs.o',
    ],

    CONFIGURE_REQUIRES => {

        # In order to specify OBJECT as an array.
        'ExtUtils::MakeMaker' => 6.84,
        'Devel::PPPort' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-TOML-XS.git',
                web => 'https://github.com/FGasper/p5-TOML-XS',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-TOML-XS/issues',
            },
        },
    },

    PREREQ_PM => {
        'Types::Serialiser' => 0,
        'XSLoader' => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::FailWarnings' => 0,
        'File::Temp' => 0,
    },
);
