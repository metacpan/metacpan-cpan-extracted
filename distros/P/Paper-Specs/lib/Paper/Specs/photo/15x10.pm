package Paper::Specs::photo::15x10;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 15,
            sheet_height => 10,
            units  => 'in',
            source => 'standard',
    }

}

1;

