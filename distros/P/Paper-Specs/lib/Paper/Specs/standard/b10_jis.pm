package Paper::Specs::standard::b10_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 32,
            sheet_height => 45,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

