package Paper::Specs::standard::b;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 11,
            sheet_height => 17,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

