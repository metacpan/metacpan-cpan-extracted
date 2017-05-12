package Paper::Specs::photo::8x6;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 8,
            sheet_height => 6,
            units  => 'in',
            source => 'standard',
    }

}

1;

