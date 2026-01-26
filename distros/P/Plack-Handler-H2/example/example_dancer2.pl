use strict;
use warnings;

use Dancer2;

get '/' => sub {
    return "Hello, World! (HTTP/2)";
};

dance;