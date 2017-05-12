package Paper::Specs::Avery::8313;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8313',
        description   => 'Glossy Photo Quality 4" x 6" Card',

        sheet_width   => 6,
        sheet_height  => 4,

        label_width   => 6,
        label_height  => 4,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 0,
        margin_top    => 0,
        margin_right  => 0,
        margin_bottom => 0,

        units         => 'in',

    };

}

1;

