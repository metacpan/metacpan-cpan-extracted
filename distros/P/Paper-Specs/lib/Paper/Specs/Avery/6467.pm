package Paper::Specs::Avery::6467;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '6467',
        description   => 'Removable ID Labels',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 1.75,
        label_height  => 0.5,

        label_rows    => 20,
        label_cols    => 4,

        margin_left   => 0.3,
        margin_top    => 0.5,
        margin_right  => 0.3,
        margin_bottom => 0.5,

        units         => 'in',

    };

}

1;

