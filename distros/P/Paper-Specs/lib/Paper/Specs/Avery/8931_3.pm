package Paper::Specs::Avery::8931_3;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8931_3',
        description   => 'CD/DVD Labels (face)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4.625,
        label_height  => 4.625,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 1.9375,
        margin_top    => 0.6875,
        margin_right  => 1.9375,
        margin_bottom => 0.6875,

        units         => 'in',

    };

}

1;

