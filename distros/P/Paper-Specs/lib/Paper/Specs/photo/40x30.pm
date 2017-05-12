package Paper::Specs::photo::40x30;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 40,
            sheet_height => 30,
            units  => 'in',
            source => 'standard',
    }

}

1;

