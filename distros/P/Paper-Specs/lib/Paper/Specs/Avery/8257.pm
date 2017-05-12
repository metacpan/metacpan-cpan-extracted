package Paper::Specs::Avery::8257;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8257',
        description   => 'Color Optimized Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.25,
        label_height  => 0.75,

        label_rows    => 10,
        label_cols    => 3,

        margin_left   => 0.375,
        margin_top    => 0.625,
        margin_right  => 0.375,
        margin_bottom => 0.625,

        units         => 'in',

    };

}

1;

