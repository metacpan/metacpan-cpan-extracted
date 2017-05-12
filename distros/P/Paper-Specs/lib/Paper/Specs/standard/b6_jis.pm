package Paper::Specs::standard::b6_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 128,
            sheet_height => 182,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

