package Paper::Specs::standard::b8_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 64,
            sheet_height => 91,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

