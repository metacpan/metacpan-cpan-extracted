package Miril::Exception;

use strict;
use warnings;
use autodie;

use Exception::Class ( 'Miril::Exception' => { fields => 'errorvar' } );

1;
