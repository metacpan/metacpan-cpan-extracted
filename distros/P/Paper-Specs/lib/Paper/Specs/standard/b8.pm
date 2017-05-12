package Paper::Specs::standard::b8;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 62,
            sheet_height => 88,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

