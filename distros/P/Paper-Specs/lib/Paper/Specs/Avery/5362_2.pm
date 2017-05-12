package Paper::Specs::Avery::5362_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5362_2',
        description   => 'Laminated Name Badge',

        sheet_width   => 8.5,
        sheet_height  => 10.9998,

        label_width   => 3.25,
        label_height  => 2,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 4.3125,
        margin_top    => 0.8333,
        margin_right  => 0.9375,
        margin_bottom => 0.8333,

        units         => 'in',

    };

}

1;

