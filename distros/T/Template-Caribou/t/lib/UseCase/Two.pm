package UseCase::Two;

use strict;
use warnings;

use Template::Caribou;
use Template::Caribou::Tags::HTML qw/ :all /;

with 'Template::Caribou::Files' => {
    dirs => [ 't/corpus/usecase_2' ],
    intro => [ 'use strict;  use warnings;' ],
};

1;


