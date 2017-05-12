package Paper::Specs::standard::b0;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 1000,
            sheet_height => 1414,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

