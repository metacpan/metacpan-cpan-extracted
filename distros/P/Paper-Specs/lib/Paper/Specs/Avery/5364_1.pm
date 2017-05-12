package Paper::Specs::Avery::5364_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5364_1',
        description   => 'Laminated Rotary Cards',

        sheet_width   => 8.5625,
        sheet_height  => 11.0207,

        label_width   => 3.875,
        label_height  => 2.0625,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 4.3125,
        margin_top    => 0.8125,
        margin_right  => 0.375,
        margin_bottom => 0.8125,

        units         => 'in',

    };

}

1;

