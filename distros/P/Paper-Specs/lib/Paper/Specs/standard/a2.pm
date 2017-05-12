package Paper::Specs::standard::a2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 420,
            sheet_height => 594,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

