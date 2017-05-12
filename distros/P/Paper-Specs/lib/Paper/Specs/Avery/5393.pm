
package Paper::Specs::Axxxx::5393;
use strict;
use base qw(Paper::Specs::base::label Paper::Specs::Axxxx);

sub specs {

	return {

        code         => '5393',
        description  => 'Name Badge Labels',

        sheet_width  => 8.5,
        sheet_height => 11,

        label_width  => 4,
        label_height => 3,

        label_rows => 3,
        label_cols => 2,

        margin_left   => 0.25,
        margin_top    => 1,
        margin_right  => 0.25,
        margin_bottom => 1,

		units => 'in',

	};

}

1;

