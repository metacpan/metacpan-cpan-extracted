#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'ExtUtils::MakeMaker'   => 6.60,
        'File::Spec'            => 0.82,
        'HTTP::Headers'         => 5.80,
        'HTTP::Request'         => 5.80,
        'HTTP::Response'        => 5.80,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'Test::More'            => 0.94,
        'URI'                   => 1.60,
    };

WriteMakefile(
    'NAME'                  => 'TemplateM',
    'DISTNAME'              => 'TemplateM',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/TemplateM.pm', 
    'ABSTRACT_FROM'         => 'lib/TemplateM.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'LICENSE'               => 'perl',
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'META_MERGE' => {
        recommends => {
            'URI'           => 1.60,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.ru',
            repository      => 'https://svn.code.sf.net/p/templatem/code/',
            license         => 'http://dev.perl.org/licenses/',
        },
    },
);
