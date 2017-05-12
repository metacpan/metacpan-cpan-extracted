package Paper::Specs::Avery::5096;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5096',
        description   => '3 1/2" Diskette Labels - Red',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.75,
        label_height  => 2.75,

        label_rows    => 3,
        label_cols    => 3,

        margin_left   => 0.125,
        margin_top    => 0.5,
        margin_right  => 0.125,
        margin_bottom => 1.75,

        units         => 'in',

    };

}

1;

