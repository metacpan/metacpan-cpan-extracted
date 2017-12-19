#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'SVG',
    VERSION_FROM  => 'lib/SVG.pm',
    PREREQ_PM     => {
        'parent'       => 0,
        'Scalar::Util' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.94',
    },
    MIN_PERL_VERSION => 5.006,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SVG-*' },
    ($] >= 5.005 ?
     (ABSTRACT_FROM  => 'lib/SVG.pm',
      LICENSE        => 'perl',
      AUTHOR         => 'Ronan Oger <ronan@cpan.com>') : ()),
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'SVG'            => { file => 'lib/SVG.pm'          , version => '2.81' },
            'SVG::DOM'       => { file => 'lib/SVG/DOM.pm'      , version => '2.81' },
            'SVG::Element'   => { file => 'lib/SVG/Element.pm'  , version => '2.81' },
            'SVG::Extension' => { file => 'lib/SVG/Extension.pm', version => '2.81' },
            'SVG::XML'       => { file => 'lib/SVG/XML.pm'      , version => '2.81' },
        },
        resources   => {
            repository => {
                type  => 'git',
                url   => 'https://github.com/manwar/SVG.git',
                web   => 'https://github.com/manwar/SVG',
            },
        },
        x_contributors => [
            'Peter Wainwright',
            'Ian Hickson',
            'Adam Schneider',
            'Steve Lihn',
            'Allen Day',
            'Gabor Szabo',
            'Mohammad S Anwar',
        ],
     })
     : ()
    ),
);
