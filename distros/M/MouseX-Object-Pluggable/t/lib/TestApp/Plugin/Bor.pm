package TestApp::Plugin::Bor;

use strict;
use warnings;
use Mouse::Role;

around bor => sub{ 'plugin bor' };

1;
