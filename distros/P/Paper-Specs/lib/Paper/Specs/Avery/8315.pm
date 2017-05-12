package Paper::Specs::Avery::8315;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8315',
        description   => 'Ink Jet Note Cards',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4.25,
        label_height  => 5.5,

        label_rows    => 2,
        label_cols    => 2,

        margin_left   => 0,
        margin_top    => 0,
        margin_right  => 0,
        margin_bottom => 0,

        units         => 'in',

    };

}

1;

