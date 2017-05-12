package Paper::Specs::standard::sra3;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 320,
            sheet_height => 450,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

