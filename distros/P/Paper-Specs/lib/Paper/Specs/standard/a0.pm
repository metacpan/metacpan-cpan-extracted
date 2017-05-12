package Paper::Specs::standard::a0;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 841,
            sheet_height => 1189,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

