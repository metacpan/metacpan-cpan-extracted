package Paper::Specs::Avery::5395;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5395',
        description   => 'Name Badge Labels - White',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 3.375,
        label_height  => 2.333,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.688,
        margin_top    => 0.583,
        margin_right  => 0.687,
        margin_bottom => 0.584,

        units         => 'in',

    };

}

1;

