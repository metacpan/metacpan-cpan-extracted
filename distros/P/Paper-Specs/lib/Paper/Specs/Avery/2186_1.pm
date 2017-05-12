package Paper::Specs::Avery::2186_1;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '2186_1',
        description   => 'Mini-Sheets Diskette Labels',

        sheet_width   => 4.25,
        sheet_height  => 10,

        label_width   => 2.75,
        label_height  => 2,

        label_rows    => 2,
        label_cols    => 1,

        margin_left   => 0.75,
        margin_top    => 0.5,
        margin_right  => 0.75,
        margin_bottom => 5.5,

        units         => 'in',

    };

}

1;

