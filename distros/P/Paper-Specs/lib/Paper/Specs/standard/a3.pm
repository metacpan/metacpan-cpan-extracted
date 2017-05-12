package Paper::Specs::standard::a3;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 297,
            sheet_height => 420,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

