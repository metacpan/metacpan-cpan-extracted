package Paper::Specs::standard::dl_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 110,
            sheet_height => 220,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

