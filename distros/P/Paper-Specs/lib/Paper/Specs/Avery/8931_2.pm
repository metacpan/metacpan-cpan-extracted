package Paper::Specs::Avery::8931_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8931_2',
        description   => 'CD/DVD Jewel Case Inserts (tray)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 5.375,
        label_height  => 4.625,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 1.5625,
        margin_top    => 0.625,
        margin_right  => 1.5625,
        margin_bottom => 5.75,

        units         => 'in',

    };

}

1;

