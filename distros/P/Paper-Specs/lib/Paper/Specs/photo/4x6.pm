package Paper::Specs::photo::4x6;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 4,
            sheet_height => 6,
            units  => 'in',
            source => 'standard',
    }

}

1;

