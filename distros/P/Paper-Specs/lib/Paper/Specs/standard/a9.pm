package Paper::Specs::standard::a9;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 37,
            sheet_height => 52,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

