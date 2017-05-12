package Paper::Specs::standard::b5_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 182,
            sheet_height => 257,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

