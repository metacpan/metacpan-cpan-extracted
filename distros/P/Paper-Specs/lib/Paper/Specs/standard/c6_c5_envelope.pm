package Paper::Specs::standard::c6_c5_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 114,
            sheet_height => 229,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

