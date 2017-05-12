package Paper::Specs::Avery::5198;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5198',
        description   => 'Audio Tape Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.5,
        label_height  => 1.667,

        label_rows    => 6,
        label_cols    => 2,

        margin_left   => 0.5,
        margin_top    => 0.5,
        margin_right  => 0.5,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

