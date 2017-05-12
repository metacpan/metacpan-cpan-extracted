package Paper::Specs::Avery::5895;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5895',
        description   => 'Name Badge Labels - Blue',

        sheet_width   => 8.502,
        sheet_height  => 11,

        label_width   => 2.938,
        label_height  => 1.896,

        label_rows    => 4,
        label_cols    => 2,

        margin_left   => 0.907,
        margin_top    => 0.802,
        margin_right  => 0.907,
        margin_bottom => 0.802,

        units         => 'in',

    };

}

1;

