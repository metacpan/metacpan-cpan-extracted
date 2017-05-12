package Paper::Specs::standard::a10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 26,
            sheet_height => 37,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

