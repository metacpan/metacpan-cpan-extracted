package Paper::Specs::photo::16x20;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 16,
            sheet_height => 20,
            units  => 'in',
            source => 'standard',
    }

}

1;

