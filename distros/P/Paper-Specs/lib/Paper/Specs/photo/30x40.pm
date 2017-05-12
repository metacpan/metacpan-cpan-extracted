package Paper::Specs::photo::30x40;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 30,
            sheet_height => 40,
            units  => 'in',
            source => 'standard',
    }

}

1;

