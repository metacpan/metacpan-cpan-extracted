package Paper::Specs::standard::b1;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 707,
            sheet_height => 1000,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

