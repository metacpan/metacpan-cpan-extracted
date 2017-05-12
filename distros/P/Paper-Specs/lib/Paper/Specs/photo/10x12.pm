package Paper::Specs::photo::10x12;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 10,
            sheet_height => 12,
            units  => 'in',
            source => 'standard',
    }

}

1;

