package Paper::Specs::Avery::5388;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5388',
        description   => 'Index Cards',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 5,
        label_height  => 3,

        label_rows    => 3,
        label_cols    => 1,

        margin_left   => 1.75,
        margin_top    => 1,
        margin_right  => 1.75,
        margin_bottom => 1,

        units         => 'in',

    };

}

1;

