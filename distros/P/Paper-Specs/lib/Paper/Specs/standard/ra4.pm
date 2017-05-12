package Paper::Specs::standard::ra4;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 215,
            sheet_height => 305,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

