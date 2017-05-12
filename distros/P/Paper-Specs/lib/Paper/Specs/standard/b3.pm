package Paper::Specs::standard::b3;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 353,
            sheet_height => 500,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

