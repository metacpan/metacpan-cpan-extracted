package Paper::Specs::standard::ra2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 430,
            sheet_height => 610,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

