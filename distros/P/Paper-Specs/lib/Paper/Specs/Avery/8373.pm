package Paper::Specs::Avery::8373;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8373',
        description   => 'Glossy Photo Quality Business Cards',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.5,
        label_height  => 2,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.5,
        margin_top    => 0.75,
        margin_right  => 0.5,
        margin_bottom => 0.75,

        units         => 'in',

    };

}

1;

