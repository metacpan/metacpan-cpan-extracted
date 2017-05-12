package Paper::Specs::standard::b4_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 257,
            sheet_height => 364,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

