package Paper::Specs::standard::legal;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 8.5,
            sheet_height => 14,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

