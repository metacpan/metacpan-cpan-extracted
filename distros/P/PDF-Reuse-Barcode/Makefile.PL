use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'PDF::Reuse::Barcode',
    'VERSION_FROM'  => 'Barcode.pm',
    'PREREQ_PM'     => {     'PDF::Reuse'                  => 0,
                             'GD::Barcode'                 => 0,
                             'GD::Barcode::Code39'         => 0,
                             'GD::Barcode::COOP2of5'       => 0,
                             'GD::Barcode::EAN13'          => 0,
                             'GD::Barcode::EAN8'           => 0,
                             'GD::Barcode::IATA2of5'       => 0,
                             'GD::Barcode::Industrial2of5' => 0,
                             'GD::Barcode::ITF'            => 0,
                             'GD::Barcode::Matrix2of5'     => 0,
                             'GD::Barcode::NW7'            => 0,
                             'GD::Barcode::UPCA'           => 0,
                             'GD::Barcode::UPCE'           => 0,
                             'Barcode::Code128'            => 0},
    LICENSE => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cnighswonger/PDF-Reuse-Barcode.git',
                web  => 'https://github.com/cnighswonger/PDF-Reuse-Barcode',
            },
            bugtracker => {
                web => 'https://github.com/cnighswonger/PDF-Reuse-Barcode/issues',
            },
        },
        provides => {
            'PDF::Reuse::Barcode' => {
                file    => 'Barcode.pm',
                version => '0.09',
            },
        },
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => [ 'Lars Lundberg larslund@cpan.org',
                       'Chris Nighswonger cnighs@cpan.org' ]) : ()),
);
