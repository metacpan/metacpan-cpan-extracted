package Paper::Specs::photo::20x30;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 20,
            sheet_height => 30,
            units  => 'in',
            source => 'standard',
    }

}

1;

