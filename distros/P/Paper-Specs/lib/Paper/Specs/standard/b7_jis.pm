package Paper::Specs::standard::b7_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 91,
            sheet_height => 128,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

