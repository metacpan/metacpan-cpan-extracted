package Paper::Specs::photo::5x7;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 5,
            sheet_height => 7,
            units  => 'in',
            source => 'standard',
    }

}

1;

