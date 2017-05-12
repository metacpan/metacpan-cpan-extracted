package Paper::Specs::standard::c4;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 229,
            sheet_height => 324,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

