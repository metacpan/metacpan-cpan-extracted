package Paper::Specs::Avery::2160_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '2160_1',
        description   => 'Mini-Sheets Filing Labels',

        sheet_width   => 4.25,
        sheet_height  => 10,

        label_width   => 2.63,
        label_height  => 1,

        label_rows    => 4,
        label_cols    => 1,

        margin_left   => 0.81,
        margin_top    => 0.5,
        margin_right  => 0.81,
        margin_bottom => 5.5,

        units         => 'in',

    };

}

1;

