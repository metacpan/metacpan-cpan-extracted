package Paper::Specs::Avery::8925_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8925_1',
        description   => 'Zip Disk Labels (face)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.345,
        label_height  => 2,

        label_rows    => 3,
        label_cols    => 2,

        margin_left   => 1.27,
        margin_top    => 0.657,
        margin_right  => 1.27,
        margin_bottom => 1.719,

        units         => 'in',

    };

}

1;

