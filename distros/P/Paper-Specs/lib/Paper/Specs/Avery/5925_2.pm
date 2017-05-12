package Paper::Specs::Avery::5925_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5925_2',
        description   => 'Zip Disk Labels (top spine)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.75,
        label_height  => 0.281,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 2.375,
        margin_top    => 2.907,
        margin_right  => 2.375,
        margin_bottom => 1.188,

        units         => 'in',

    };

}

1;

