package Paper::Specs::Avery::5305;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5305',
        description   => 'Tent Card - Medium',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 7.75,
        label_height  => 4.25,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 0.375,
        margin_top    => 0.875,
        margin_right  => 0.375,
        margin_bottom => 0.875,

        units         => 'in',

    };

}

1;

