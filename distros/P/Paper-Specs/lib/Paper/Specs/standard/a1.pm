package Paper::Specs::standard::a1;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 594,
            sheet_height => 841,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

