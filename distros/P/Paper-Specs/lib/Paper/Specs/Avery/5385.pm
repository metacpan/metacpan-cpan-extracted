package Paper::Specs::Avery::5385;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5385',
        description   => 'Rotary Cards - Small',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4,
        label_height  => 2.167,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.25,
        margin_top    => 1.1667,
        margin_right  => 0.25,
        margin_bottom => 1.1667,

        units         => 'in',

    };

}

1;

