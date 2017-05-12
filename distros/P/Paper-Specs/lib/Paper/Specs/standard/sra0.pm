package Paper::Specs::standard::sra0;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 900,
            sheet_height => 1280,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

