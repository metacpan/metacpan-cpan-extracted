package Paper::Specs::standard::a8;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 52,
            sheet_height => 74,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

