package Paper::Specs::standard::c5_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 162,
            sheet_height => 229,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

