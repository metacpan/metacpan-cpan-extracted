package Paper::Specs::Avery::2164_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '2164_1',
        description   => 'Mini-Sheets Mailing Labels',

        sheet_width   => 4.25,
        sheet_height  => 10,

        label_width   => 4,
        label_height  => 3.3125,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 0.125,
        margin_top    => 0.84375,
        margin_right  => 0.125,
        margin_bottom => 5.84375,

        units         => 'in',

    };

}

1;

