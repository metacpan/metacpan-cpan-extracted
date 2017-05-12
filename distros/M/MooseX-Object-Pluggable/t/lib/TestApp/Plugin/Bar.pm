package TestApp::Plugin::Bar;

use strict;
use warnings;
use Moose::Role;

around bar => sub{ 'override bar' };

1;
