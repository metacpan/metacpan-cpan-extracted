package Paper::Specs::photo::7x5;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 7,
            sheet_height => 5,
            units  => 'in',
            source => 'standard',
    }

}

1;

