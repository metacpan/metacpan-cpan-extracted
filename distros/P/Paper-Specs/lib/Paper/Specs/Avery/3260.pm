package Paper::Specs::Avery::3260;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '3260',
        description   => 'Embossed Half-Fold Cards',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 7,
        label_height  => 4,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 0.75,
        margin_top    => 0.75,
        margin_right  => 0.75,
        margin_bottom => 0.75,

        units         => 'in',

    };

}

1;

