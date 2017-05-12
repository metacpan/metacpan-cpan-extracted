package Paper::Specs::photo::30x20;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 30,
            sheet_height => 20,
            units  => 'in',
            source => 'standard',
    }

}

1;

