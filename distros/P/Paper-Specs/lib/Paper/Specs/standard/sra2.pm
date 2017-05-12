package Paper::Specs::standard::sra2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 450,
            sheet_height => 640,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

