package Paper::Specs::Avery::5662;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5662',
        description   => 'Clear Mailing Labels',

        sheet_width   => 8.5,
        sheet_height  => 11.001,

        label_width   => 4.125,
        label_height  => 1.333,

        label_rows    => 7,
        label_cols    => 2,

        margin_left   => 0.083,
        margin_top    => 0.835,
        margin_right  => 0.083,
        margin_bottom => 0.835,

        units         => 'in',

    };

}

1;

