package Paper::Specs::standard::b5_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 176,
            sheet_height => 250,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

