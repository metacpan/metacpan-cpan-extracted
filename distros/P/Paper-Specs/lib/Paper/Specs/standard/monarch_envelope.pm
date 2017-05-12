package Paper::Specs::standard::monarch_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 3.875,
            sheet_height => 7.5,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

