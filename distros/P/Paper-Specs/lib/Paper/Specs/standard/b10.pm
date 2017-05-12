package Paper::Specs::standard::b10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 31,
            sheet_height => 44,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

