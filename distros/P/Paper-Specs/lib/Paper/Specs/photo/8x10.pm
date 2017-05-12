package Paper::Specs::photo::8x10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 8,
            sheet_height => 10,
            units  => 'in',
            source => 'standard',
    }

}

1;

