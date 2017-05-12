package UseCase::One;

use strict;
use warnings;

use Template::Caribou;

use Template::Caribou::Tags::HTML ':all';

with 'Template::Caribou::Files' => {
    intro => [ 'use strict; use 5.10.0;' ],
};

1;
