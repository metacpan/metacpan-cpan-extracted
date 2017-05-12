package Config::Routes;

use strict;
use warnings;

use Pinwheel::Controller;

Pinwheel::Controller::connect('hello_world',
    '/',
    controller => 'hello_world',
    action => 'index',
);

1;
