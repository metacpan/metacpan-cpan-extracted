package Paper::Specs::Avery::5997_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5997_1',
        description   => 'Videotape Face Labels',

        sheet_width   => 8.501,
        sheet_height  => 11.0002,

        label_width   => 3.063,
        label_height  => 1.833,

        label_rows    => 5,
        label_cols    => 2,

        margin_left   => 1.069,
        margin_top    => 0.917,
        margin_right  => 1.069,
        margin_bottom => 0.917,

        units         => 'in',

    };

}

1;

