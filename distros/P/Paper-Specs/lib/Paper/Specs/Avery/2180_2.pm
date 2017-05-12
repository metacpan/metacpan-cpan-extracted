package Paper::Specs::Avery::2180_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '2180_2',
        description   => 'Mini-Sheets Filing Labels',

        sheet_width   => 4.25,
        sheet_height  => 10,

        label_width   => 3.4375,
        label_height  => 0.6875,

        label_rows    => 6,
        label_cols    => 1,

        margin_left   => 0.40625,
        margin_top    => 5.5,
        margin_right  => 0.40625,
        margin_bottom => 0.375,

        units         => 'in',

    };

}

1;

