package Paper::Specs::Avery::5293;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5293',
        description   => 'Round Labels',

        sheet_width   => 8.501,
        sheet_height  => 10.96,

        label_width   => 1.625,
        label_height  => 1.625,

        label_rows    => 6,
        label_cols    => 4,

        margin_left   => 0.438,
        margin_top    => 0.5,
        margin_right  => 0.438,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

