package Paper::Specs::standard::b2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 500,
            sheet_height => 707,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

