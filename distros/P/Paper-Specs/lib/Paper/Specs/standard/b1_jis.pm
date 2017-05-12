package Paper::Specs::standard::b1_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 728,
            sheet_height => 1030,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

