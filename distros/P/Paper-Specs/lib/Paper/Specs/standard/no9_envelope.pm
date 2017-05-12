package Paper::Specs::standard::no9_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 3.875,
            sheet_height => 8.875,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

