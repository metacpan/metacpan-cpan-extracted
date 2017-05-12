package Paper::Specs::standard::c2;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 458,
            sheet_height => 648,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

