package Paper::Specs::Avery::5960;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5960',
        description   => 'Mailing Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 2.625,
        label_height  => 1,

        label_rows    => 10,
        label_cols    => 3,

        margin_left   => 0.1875,
        margin_top    => 0.5,
        margin_right  => 0.1875,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

