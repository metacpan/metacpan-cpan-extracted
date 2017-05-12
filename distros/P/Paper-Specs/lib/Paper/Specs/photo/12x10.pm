package Paper::Specs::photo::12x10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 12,
            sheet_height => 10,
            units  => 'in',
            source => 'standard',
    }

}

1;

