package Paper::Specs::photo::9x6;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 9,
            sheet_height => 6,
            units  => 'in',
            source => 'standard',
    }

}

1;

