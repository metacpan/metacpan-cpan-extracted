use strict;
use Test::More tests => 6;

use_ok('MooseX::Async');

require_ok('MooseX::Async::Meta::Trait');
require_ok('MooseX::Async::Meta::Class');
require_ok('MooseX::Async::Meta::Role');

ok( Moose::Util::does_role( "MooseX::Async::Meta::$_", 'MooseX::Async::Meta::Trait' ), "Meta::$_ does Trait" ) for qw(Class Role);
