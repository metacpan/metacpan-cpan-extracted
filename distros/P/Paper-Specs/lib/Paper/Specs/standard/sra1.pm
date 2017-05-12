package Paper::Specs::standard::sra1;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 640,
            sheet_height => 900,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

