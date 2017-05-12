package Paper::Specs::Avery::5164;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5164',
        description   => 'Mailing Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 4,
        label_height  => 3.333,

        label_rows    => 3,
        label_cols    => 2,

        margin_left   => 0.156,
        margin_top    => 0.5,
        margin_right  => 0.156,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

