package Paper::Specs::standard::no14_envelope;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 5,
            sheet_height => 11.5,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

