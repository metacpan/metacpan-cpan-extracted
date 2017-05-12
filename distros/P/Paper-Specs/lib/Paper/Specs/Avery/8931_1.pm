package Paper::Specs::Avery::8931_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8931_1',
        description   => 'CD/DVD Jewel Case Inserts (cover)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4.75,
        label_height  => 4.75,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 1.875,
        margin_top    => 5.625,
        margin_right  => 1.875,
        margin_bottom => 0.625,

        units         => 'in',

    };

}

1;

