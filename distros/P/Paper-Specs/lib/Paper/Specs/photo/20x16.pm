package Paper::Specs::photo::20x16;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 20,
            sheet_height => 16,
            units  => 'in',
            source => 'standard',
    }

}

1;

