package Paper::Specs::Avery::5309;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5309',
        description   => 'Tent Card - Large',

        sheet_width   => 11,
        sheet_height  => 8.5,

        label_width   => 10,
        label_height  => 6,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 0.5,
        margin_top    => 1.25,
        margin_right  => 0.5,
        margin_bottom => 1.25,

        units         => 'in',

    };

}

1;

