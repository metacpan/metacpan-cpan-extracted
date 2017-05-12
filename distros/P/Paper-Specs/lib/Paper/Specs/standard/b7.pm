package Paper::Specs::standard::b7;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 88,
            sheet_height => 125,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

