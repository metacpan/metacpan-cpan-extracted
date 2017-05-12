package Paper::Specs::Avery::8925_3;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8925_3',
        description   => 'Zip Disk Labels (bottom spine)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.75,
        label_height  => 0.281,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 2.375,
        margin_top    => 3.438,
        margin_right  => 2.375,
        margin_bottom => 0.657,

        units         => 'in',

    };

}

1;

