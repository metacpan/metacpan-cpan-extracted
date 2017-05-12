package Paper::Specs::standard::sra4;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 225,
            sheet_height => 320,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

