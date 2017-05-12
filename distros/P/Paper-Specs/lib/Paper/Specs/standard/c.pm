package Paper::Specs::standard::c;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 17,
            sheet_height => 22,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

