package Paper::Specs::standard::d;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 22,
            sheet_height => 34,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

