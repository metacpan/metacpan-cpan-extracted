package Paper::Specs::Avery::5824;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5824',
        description   => 'CD Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4.5,
        label_height  => 4.5,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 2,
        margin_top    => 0.5,
        margin_right  => 2,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

