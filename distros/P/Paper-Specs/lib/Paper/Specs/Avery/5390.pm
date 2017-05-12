package Paper::Specs::Avery::5390;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5390',
        description   => 'Insertable Name Badges - 2 1/4" x 3 1/2"',

        sheet_width   => 8.5,
        sheet_height  => 11.001,

        label_width   => 3.5,
        label_height  => 2.219,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.75,
        margin_top    => 1.0625,
        margin_right  => 0.75,
        margin_bottom => 1.0625,

        units         => 'in',

    };

}

1;

