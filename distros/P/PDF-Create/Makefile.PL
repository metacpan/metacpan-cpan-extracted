#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'PDF::Create',
    VERSION_FROM       => 'lib/PDF/Create.pm',
    ABSTRACT_FROM      => 'lib/PDF/Create.pm',
    LICENSE            => "perl",
    EXE_FILES          => [ 'eg/verify-char-width' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => 0,
    },
    PREREQ_PM => {
        'JSON'         => 0,
        'Carp'         => 0,
        'FileHandle'   => 0,
        'Data::Dumper' => 0,
        'Scalar::Util' => 0,
        'File::Share'  => '0.25',
    },
    TEST_REQUIRES => {
        'Test::More'      => '1.00',
        'Test::LeakTrace' => '0.14',
        'File::Temp'      => 0,
    },
    dist       => { COMPRESS => "gzip", SUFFIX => "gz" },
    clean      => { FILES => 'PDF-Create*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PDF::Create'          => { file => 'lib/PDF/Create.pm'        , version => '1.42' },
            'PDF::Create::Page'    => { file => 'lib/PDF/Create/Page.pm'   , version => '1.42' },
            'PDF::Create::Outline' => { file => 'lib/PDF/Create/Outline.pm', version => '1.42' },
            'PDF::Image::GIF'      => { file => 'lib/PDF/Image/GIF.pm'     , version => '1.42' },
            'PDF::Image::JPEG'     => { file => 'lib/PDF/Image/JPEG.pm'    , version => '1.42' },
            'PDF::Font'            => { file => 'lib/PDF/Font.pm'          , version => '1.42' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'http://github.com/manwar/pdf-create.git',
                web  => 'http://github.com/manwar/pdf-create',
            }
	}
    },
);

package MY;
use File::ShareDir::Install 'postamble';
