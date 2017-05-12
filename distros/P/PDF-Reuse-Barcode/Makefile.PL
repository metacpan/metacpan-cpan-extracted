use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'PDF::Reuse::Barcode',
    'VERSION_FROM'  => 'Barcode.pm',
    'PREREQ_PM'     => {     PDF::Reuse                  => 0,
                             GD::Barcode                 => 0,
                             GD::Barcode::Code39         => 0,
                             GD::Barcode::COOP2of5       => 0,
                             GD::Barcode::EAN13          => 0,
                             GD::Barcode::EAN8           => 0,
                             GD::Barcode::IATA2of5       => 0,
                             GD::Barcode::Industrial2of5 => 0,
                             GD::Barcode::ITF            => 0,
                             GD::Barcode::Matrix2of5     => 0,
                             GD::Barcode::NW7            => 0,
                             GD::Barcode::UPCA           => 0,
                             GD::Barcode::UPCE           => 0,
                             Barcode::Code128            => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Lars Lundberg larslund@cpan.org') : ()),
);
