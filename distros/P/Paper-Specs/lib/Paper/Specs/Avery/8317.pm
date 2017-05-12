package Paper::Specs::Avery::8317;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8317',
        description   => 'Embossed Note Cards - Ivory',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.25,
        label_height  => 4.5,

        label_rows    => 2,
        label_cols    => 2,

        margin_left   => 0.5,
        margin_top    => 0.5,
        margin_right  => 0.5,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

