package Paper::Specs::Avery::8165;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '8165',
        description   => 'Full Sheet Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 8.5,
        label_height  => 11,

        label_rows    => 1,
        label_cols    => 1,

        margin_left   => 0,
        margin_top    => 0,
        margin_right  => 0,
        margin_bottom => 0,

        units         => 'in',

    };

}

1;

