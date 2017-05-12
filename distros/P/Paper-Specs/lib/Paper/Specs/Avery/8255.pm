package Paper::Specs::Avery::8255;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8255',
        description   => 'Color Optimized Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 8.5,
        label_height  => 11,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 0,
        margin_top    => 0,
        margin_right  => 0,
        margin_bottom => 0,

        units         => 'in',

    };

}

1;

