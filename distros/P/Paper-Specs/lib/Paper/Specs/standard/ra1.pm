package Paper::Specs::standard::ra1;
use strict;
use base qw(Paper::Specs::base::sheet);

sub specs {

    {
            sheet_width  => 610,
            sheet_height => 860,
            units  => 'mm',
            source => 'ISO 216',
    }

}

1;

