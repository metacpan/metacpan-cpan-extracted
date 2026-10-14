package State::Store::ABI::Consumer;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('State::Store::ABI::Consumer', $VERSION);

1;
