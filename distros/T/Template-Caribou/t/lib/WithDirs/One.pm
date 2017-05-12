package WithDirs::One;

use strict;
use warnings;
use 5.10.0 ;

use Template::Caribou;

use experimental 'signatures';

with 'Template::Caribou::Files' => {
    intro => [
        'use 5.10.0;',
        q{ use experimental 'signatures'; },
    ],
};

1;
