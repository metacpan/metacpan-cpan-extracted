package Paper::Specs::photo::6x4;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 6,
            sheet_height => 4,
            units  => 'in',
            source => 'standard',
    }

}

1;

