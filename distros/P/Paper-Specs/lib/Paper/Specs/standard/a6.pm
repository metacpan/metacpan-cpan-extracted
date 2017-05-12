package Paper::Specs::standard::a6;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 105,
            sheet_height => 148,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

