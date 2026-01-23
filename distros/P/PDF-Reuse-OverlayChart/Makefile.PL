use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'PDF::Reuse::OverlayChart',
    'VERSION_FROM'  => 'OverlayChart.pm',
    'PREREQ_PM'     => { 'PDF::Reuse' => 0 },
    LICENSE => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cnighswonger/PDF-Reuse-OverlayChart.git',
                web  => 'https://github.com/cnighswonger/PDF-Reuse-OverlayChart',
            },
            bugtracker => {
                web => 'https://github.com/cnighswonger/PDF-Reuse-OverlayChart/issues',
            },
        },
        provides => {
            'PDF::Reuse::OverlayChart' => {
                file    => 'OverlayChart.pm',
                version => '0.05',
            },
        },
    },
    ($] >= 5.005 ?
      (AUTHOR     => [ 'Lars Lundberg larslund@cpan.org',
                       'Chris Nighswonger cnighs@cpan.org' ]) : ()),
);
