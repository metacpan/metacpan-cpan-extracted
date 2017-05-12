package Paper::Specs::standard::no10_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 4.125,
            sheet_height => 9.5,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

