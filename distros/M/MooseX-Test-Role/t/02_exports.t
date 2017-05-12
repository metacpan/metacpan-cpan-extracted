use strict;
use warnings;

use Test::More tests => 4;

use MooseX::Test::Role;
can_ok( __PACKAGE__, 'requires_ok' );
can_ok( __PACKAGE__, 'consumer_of' );
can_ok( __PACKAGE__, 'consuming_object' );
can_ok( __PACKAGE__, 'consuming_class' );
