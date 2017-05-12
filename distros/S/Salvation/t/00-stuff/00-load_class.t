use strict;

use Test::More tests => 7;

use Salvation::Stuff '&load_class';

ok( &load_class( $_ ), $_ ) for 'Salvation::System', 'Salvation::Service', 'Salvation::Service::View', 'Salvation::Service::Model', 'Salvation::Service::Controller';

ok( !&load_class( $_ ), $_ ) for 'Salvation::_some_unexistent_stuff', '_some_unexistent_stuff_for_salvation';

