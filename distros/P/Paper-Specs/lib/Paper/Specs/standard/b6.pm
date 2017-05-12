package Paper::Specs::standard::b6;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 125,
            sheet_height => 176,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

