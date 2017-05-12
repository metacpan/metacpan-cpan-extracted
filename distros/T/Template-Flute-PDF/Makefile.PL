use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Flute::PDF',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Template/Flute/PDF.pm',
    ABSTRACT_FROM       => 'lib/Template/Flute/PDF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'CAM::PDF' => 0,
    },
    PREREQ_PM => {
        'Template::Flute' => 0.0025,
        'Template::Flute::Style::CSS' => 0.0030,
	'PDF::API2' => 0,
        'Image::Size' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Flute-PDF-*' },
);
