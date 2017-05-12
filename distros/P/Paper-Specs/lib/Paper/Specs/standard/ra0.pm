package Paper::Specs::standard::ra0;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 860,
            sheet_height => 1220,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

