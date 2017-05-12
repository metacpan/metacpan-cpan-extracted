package Paper::Specs::standard::b4_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 250,
            sheet_height => 353,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

