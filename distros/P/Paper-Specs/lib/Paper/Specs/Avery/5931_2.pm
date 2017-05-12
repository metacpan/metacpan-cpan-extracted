package Paper::Specs::Avery::5931_2;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5931_2',
        description   => 'White CD/DVD Labels (spines)',

        sheet_width   => 8.5,
        sheet_height  => 11,

        label_width   => 0.219,
        label_height  => 4.688,

        label_rows    => 2,
        label_cols    => 2,

        margin_left   => 0.494,
        margin_top    => 0.734,
        margin_right  => 7.318,
        margin_bottom => 0.733,

        units         => 'in',

    };

}

1;

