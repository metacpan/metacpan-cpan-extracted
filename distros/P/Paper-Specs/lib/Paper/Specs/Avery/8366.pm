package Paper::Specs::Avery::8366;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8366',
        description   => 'Filing Labels - White',

        sheet_width   => 8.484,
        sheet_height  => 11,

        label_width   => 3.438,
        label_height  => 0.666,

        label_rows    => 15,
        label_cols    => 2,

        margin_left   => 0.539,
        margin_top    => 0.505,
        margin_right  => 0.539,
        margin_bottom => 0.505,

        units         => 'in',

    };

}

1;

