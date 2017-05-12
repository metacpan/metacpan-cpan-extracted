package Paper::Specs::Avery::74552;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74552',
        description   => 'Insertable Name Badges - 2" x 3"',

        sheet_width   => 8.5,
        sheet_height  => 11.0013,

        label_width   => 3,
        label_height  => 1.969,

        label_rows    => 5,
        label_cols    => 2,

        margin_left   => 1.25,
        margin_top    => 0.5625,
        margin_right  => 1.25,
        margin_bottom => 0.5938,

        units         => 'in',

    };

}

1;

