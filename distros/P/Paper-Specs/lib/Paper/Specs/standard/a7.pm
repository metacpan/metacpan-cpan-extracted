package Paper::Specs::standard::a7;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 74,
            sheet_height => 105,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

