use strict;
use warnings;

use Test::More tests => 2;

use_ok('MooseX::Test::Role');
ok( !MooseX::Test::Role->can('new'), 'shouldn\'t be a Moose class' );
