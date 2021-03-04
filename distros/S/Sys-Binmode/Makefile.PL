use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::Binmode',
    VERSION_FROM      => 'lib/Sys/Binmode.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sys/Binmode.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-Wall -I.', # e.g., '-I. -I/usr/include/other'
    LICENSE           => "perl_5",

    # We need cop_hints_fetch_pvs(). (cf. Devel::PPPort)
    MIN_PERL_VERSION => '5.14.0',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Sys-Binmode.git',
                web => 'https://github.com/FGasper/p5-Sys-Binmode',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Sys-Binmode/issues',
            },
        },
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::FailWarnings' => 0,
        'File::Temp' => 0,
    },
);
