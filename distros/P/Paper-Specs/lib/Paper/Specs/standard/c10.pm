package Paper::Specs::standard::c10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 28,
            sheet_height => 40,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

