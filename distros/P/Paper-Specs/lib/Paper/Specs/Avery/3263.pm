package Paper::Specs::Avery::3263;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '3263',
        description   => 'Postcards',

        sheet_width   => 11,
        sheet_height  => 8.5,

        label_width   => 5.5,
        label_height  => 4.25,

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

