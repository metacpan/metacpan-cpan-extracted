package Paper::Specs::Avery::6879;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '6879',
        description   => 'Mailing Labels for Color Printing',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.75,
        label_height  => 1.25,

        label_rows    => 6,
        label_cols    => 2,

        margin_left   => 0.375,
        margin_top    => 1.125,
        margin_right  => 0.375,
        margin_bottom => 1.125,

        units         => 'in',

    };

}

1;

