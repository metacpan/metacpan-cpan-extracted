package Paper::Specs::standard::c1;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 648,
            sheet_height => 917,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

