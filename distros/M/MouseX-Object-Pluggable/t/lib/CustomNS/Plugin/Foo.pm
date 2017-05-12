package CustomNS::Plugin::Foo;

use strict;
use warnings;
use Mouse::Role;

around foo => sub{ 'around foo CNS' };

1;
