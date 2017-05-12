package Paper::Specs::standard::a5;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 148,
            sheet_height => 210,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

