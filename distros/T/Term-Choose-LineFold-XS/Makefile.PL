use 5.16.0;
use warnings;
use strict;
use ExtUtils::MakeMaker;

my $define = $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ? '-DAMBIGUOUS_WIDTH_IS_WIDE' : '';


WriteMakefile(
    MIN_PERL_VERSION => '5.16.0',
    LICENSE => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => "https://github.com/kuerbis/Term-Choose-LineFold-XS/issues",
            },
            repository => {
              type => 'git',
              web  => 'https://github.com/kuerbis/Term-Choose-LineFold-XS',
              url  => 'https://github.com/kuerbis/Term-Choose-LineFold-XS.git',
            },
        },
    },
    AUTHOR         => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME           => 'Term::Choose::LineFold::XS',
    ABSTRACT_FROM  => 'lib/Term/Choose/LineFold/XS.pm',
    VERSION_FROM   => 'lib/Term/Choose/LineFold/XS.pm',
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'open'       => 0,
    },
    PREREQ_PM => {
        'strict'   => 0,
        'warnings' => 0,
        'Exporter' => 0,
        'XSLoader' => 0,
    },
    LIBS  => [''],
    DEFINE => $define,
    INC    => '-I.',
    XS => {
        'XS.xs' => 'XS.c'
    },
);
