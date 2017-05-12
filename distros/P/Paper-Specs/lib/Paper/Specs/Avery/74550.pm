package Paper::Specs::Avery::74550;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74550',
        description   => 'Insertable Name Badges - 2 1/4" x 3 1/2"',

        sheet_width   => 4.25,
        sheet_height  => 10.5002,

        label_width   => 3.5,
        label_height  => 2.2188,

        label_rows    => 4,
        label_cols    => 1,

        margin_left   => 0.375,
        margin_top    => 1.0625,
        margin_right  => 0.375,
        margin_bottom => 0.5625,

        units         => 'in',

    };

}

1;

