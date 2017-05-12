package Paper::Specs::standard::no12_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 4.75,
            sheet_height => 11,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

