package TestApp2::Plugin::Foo;

use strict;
use warnings;
use Mouse::Role;

around foo => sub{ 'around foo 2' };

1;
