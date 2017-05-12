package Paper::Specs::standard::c3;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 324,
            sheet_height => 458,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

