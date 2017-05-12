package TestApp::Plugin::Bor;

use strict;
use warnings;
use Moose::Role;

around bor => sub{ 'plugin bor' };

1;
