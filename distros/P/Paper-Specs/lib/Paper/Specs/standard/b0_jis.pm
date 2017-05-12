package Paper::Specs::standard::b0_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 1030,
            sheet_height => 1456,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

