package Paper::Specs::standard::a4;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 210,
            sheet_height => 297,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

