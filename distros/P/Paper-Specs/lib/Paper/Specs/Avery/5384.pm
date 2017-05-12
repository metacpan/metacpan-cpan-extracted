package Paper::Specs::Avery::5384;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5384',
        description   => 'Insertable Name Badges - 3" x 4"',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4,
        label_height  => 3,

        label_rows    => 3,
        label_cols    => 2,

        margin_left   => 0.25,
        margin_top    => 1,
        margin_right  => 0.25,
        margin_bottom => 1,

        units         => 'in',

    };

}

1;

