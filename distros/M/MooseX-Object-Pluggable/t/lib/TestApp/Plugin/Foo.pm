package TestApp::Plugin::Foo;

use strict;
use warnings;
use Moose::Role;

around foo => sub{ 'around foo' };

1;
