package Paper::Specs::Avery::74551;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74551',
        description   => 'Insertable Name Badges - 2 1/2" x 3 3/4"',

        sheet_width   => 8.5,
        sheet_height  => 11.001,

        label_width   => 3.75,
        label_height  => 2.469,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.5,
        margin_top    => 0.5625,
        margin_right  => 0.5,
        margin_bottom => 0.5625,

        units         => 'in',

    };

}

1;

