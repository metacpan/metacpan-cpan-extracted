package Paper::Specs::Avery::5883;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5883',
        description   => 'Insertable Name Badges - 2 1/4" x 3 1/2"',

        sheet_width   => 8.5,
        sheet_height  => 11.0313,

        label_width   => 3.1875,
        label_height  => 1.8438,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.875,
        margin_top    => 1.3125,
        margin_right  => 0.9375,
        margin_bottom => 1.3125,

        units         => 'in',

    };

}

1;

