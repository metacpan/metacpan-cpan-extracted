package Paper::Specs::standard::no7_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 3.75,
            sheet_height => 6.75,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

