package TestApp::Plugin::Foo;

use strict;
use warnings;
use Mouse::Role;

around foo => sub{ 'around foo' };

1;
