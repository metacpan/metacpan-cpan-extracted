package Paper::Specs::Avery::74520;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74520',
        description   => 'Insertable Name Badges - 3" x 4"',

        sheet_width   => 4.25,
        sheet_height  => 11,

        label_width   => 4,
        label_height  => 3,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 0.25,
        margin_top    => 1,
        margin_right  => 0,
        margin_bottom => 1,

        units         => 'in',

    };

}

1;

