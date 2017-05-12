package Paper::Specs::standard::b9;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 44,
            sheet_height => 62,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

