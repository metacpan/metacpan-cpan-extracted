package Paper::Specs::standard::e4_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 280,
            sheet_height => 400,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

