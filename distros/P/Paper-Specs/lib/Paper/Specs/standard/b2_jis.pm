package Paper::Specs::standard::b2_jis;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 515,
            sheet_height => 728,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

