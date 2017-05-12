package Paper::Specs::standard::ra3;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 305,
            sheet_height => 430,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

