package Paper::Specs::Avery::74650;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74650',
        description   => 'Insertable Name Badges - 2 1/4" x 3 1/2"',

        sheet_width   => 4.25,
        sheet_height  => 10.5003,

        label_width   => 3.5,
        label_height  => 2.2188,

        label_rows    => 4,
        label_cols    => 1,

        margin_left   => 0.375,
        margin_top    => 0.9688,
        margin_right  => 0.375,
        margin_bottom => 0.6563,

        units         => 'in',

    };

}

1;

