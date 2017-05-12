package Paper::Specs::standard::id_2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 125,
            sheet_height => 88,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

