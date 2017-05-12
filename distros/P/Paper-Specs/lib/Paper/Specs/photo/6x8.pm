package Paper::Specs::photo::6x8;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 6,
            sheet_height => 8,
            units  => 'in',
            source => 'standard',
    }

}

1;

