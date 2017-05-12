package Paper::Specs::Avery::5262;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Avery);

sub specs {

    return {

        code          => '5262',
        description   => 'Mailing Labels',

        sheet_width   => 8.4995,
        sheet_height  => 10.9997,

        label_width   => 4,
        label_height  => 1.3333,

        label_rows    => 7,
        label_cols    => 2,

        margin_left   => 0.156,
        margin_top    => 0.8333,
        margin_right  => 0.156,
        margin_bottom => 0.8333,

        units         => 'in',

    };

}

1;

