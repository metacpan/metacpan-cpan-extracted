package Paper::Specs::Avery::8389;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8389',
        description   => 'Glossy Photo Quality Postcards',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 6,
        label_height  => 4,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 1.25,
        margin_top    => 1.25,
        margin_right  => 1.25,
        margin_bottom => 1.25,

        units         => 'in',

    };

}

1;

