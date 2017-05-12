package Paper::Specs::standard::no11_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 4.5,
            sheet_height => 10.375,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

