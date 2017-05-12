package CustomNS::Plugin::Foo;

use strict;
use warnings;
use Moose::Role;

around foo => sub{ 'around foo CNS' };

1;
