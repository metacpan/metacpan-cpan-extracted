package Paper::Specs::Avery::5294;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5294',
        description   => 'Round Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.468,
        label_height  => 2.468,

        label_rows    => 4,
        label_cols    => 3,

        margin_left   => 0.266,
        margin_top    => 0.516,
        margin_right  => 0.266,
        margin_bottom => 0.516,

        units         => 'in',

    };

}

1;

