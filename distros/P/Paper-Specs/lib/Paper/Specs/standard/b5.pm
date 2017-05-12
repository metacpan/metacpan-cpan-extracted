package Paper::Specs::standard::b5;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 176,
            sheet_height => 250,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

