use strict;
use warnings;
BEGIN { eval q{ use EV } } # supress CHECK block warning, if EV is installed
use Test::More tests => 4;

use_ok 'Test::Clustericious::Cluster';
use_ok 'Mojolicious::Plugin::PlugAuthLite';
use_ok 'PlugAuth::Lite';
use_ok 'Test::PlugAuth';
