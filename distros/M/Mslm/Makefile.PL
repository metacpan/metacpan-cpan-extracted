use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mslm',
    VERSION_FROM      => 'lib/Mslm.pm',
    PREREQ_PM         => {
        'LWP::UserAgent'          => '0',
        'JSON'                    => '0',
        'URI'                     => '0',
        'Exporter'                => '0'
    },
    ABSTRACT_FROM     => 'lib/Mslm.pm',
    AUTHOR            => 'Mslm <usama.liaqat@mslm.io>',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mslm-*' },
    LICENSE           => 'mit'
);

package MY;
