package Paper::Specs::Avery::6490;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '6490',
        description   => 'Removable Labels - 3 1/2" Diskette',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.688,
        label_height  => 2,

        label_rows    => 5,
        label_cols    => 3,

        margin_left   => 0.125,
        margin_top    => 0.5,
        margin_right  => 0.125,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

