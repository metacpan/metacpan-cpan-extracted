package Paper::Specs::standard::a;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 8.5,
            sheet_height => 11,
            units  => 'in',
            source => 'educated guess',
    }

}

1;

