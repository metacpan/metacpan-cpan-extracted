use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME             => 'PDF::FacturX',
    AUTHOR           => 'huguesmax',
    VERSION_FROM     => 'lib/PDF/FacturX.pm',
    ABSTRACT         => 'Generate Factur-X / ZUGFeRD-compatible PDF/A-3 invoices (EN 16931)',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.020',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'      => '7.00',
        'File::ShareDir::Install'  => '0.13',
    },

    PREREQ_PM => {
        'XML::LibXML'      => '2.0',
        'PDF::Builder'     => '3.020',
        'File::ShareDir'   => '1.116',
        'File::Temp'       => '0',
        'File::Basename'   => '0',
        'POSIX'            => '0',
        'Encode'           => '0',
        'Exporter'         => '0',
    },

    TEST_REQUIRES => {
        'Test::More'      => '1.302',
        'Compress::Zlib'  => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/huguesmax/PDF-FacturX',
            repository => {
                type => 'git',
                url  => 'https://github.com/huguesmax/PDF-FacturX.git',
                web  => 'https://github.com/huguesmax/PDF-FacturX',
            },
            bugtracker => {
                web => 'https://github.com/huguesmax/PDF-FacturX/issues',
            },
        },
        keywords => [qw(factur-x facturx zugferd pdf invoice en16931 pdfa3 cii)],
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PDF-FacturX-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
