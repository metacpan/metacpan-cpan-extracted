package Paper::Specs::Avery::74558;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '74558',
        description   => 'Insertable Name Badges - 2" x 3"',

        sheet_width   => 8.5,
        sheet_height  => 10.9998,

        label_width   => 3,
        label_height  => 1.969,

        label_rows    => 5,
        label_cols    => 2,

        margin_left   => 1.25,
        margin_top    => 0.626,
        margin_right  => 1.25,
        margin_bottom => 0.5288,

        units         => 'in',

    };

}

1;

