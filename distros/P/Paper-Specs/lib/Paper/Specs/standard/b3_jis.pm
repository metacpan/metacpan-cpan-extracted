package Paper::Specs::standard::b3_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 364,
            sheet_height => 515,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

