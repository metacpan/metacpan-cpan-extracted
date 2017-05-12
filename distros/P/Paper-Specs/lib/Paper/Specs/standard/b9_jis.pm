package Paper::Specs::standard::b9_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 45,
            sheet_height => 64,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

