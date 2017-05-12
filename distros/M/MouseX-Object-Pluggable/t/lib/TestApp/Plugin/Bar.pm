package TestApp::Plugin::Bar;

use strict;
use warnings;
use Mouse::Role;

around bar => sub{ 'override bar' };

1;
