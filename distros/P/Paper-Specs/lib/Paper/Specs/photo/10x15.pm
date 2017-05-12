package Paper::Specs::photo::10x15;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 10,
            sheet_height => 15,
            units  => 'in',
            source => 'standard',
    }

}

1;

