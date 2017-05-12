package Paper::Specs::Avery::5997_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5997_2',
        description   => 'Videotape Spine Labels',

        sheet_width   => 8.501,
        sheet_height  => 10.999,

        label_width   => 5.813,
        label_height  => 0.6666,

        label_rows    => 15,
        label_cols    => 1,

        margin_left   => 1.344,
        margin_top    => 0.5,
        margin_right  => 1.344,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

