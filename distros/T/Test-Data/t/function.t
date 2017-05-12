use Test::More tests => 2;
use Test::Data qw(Function);

sub fooey($$) { 1 }

prototype_ok( &fooey, '$$', 'Double scalar fooey' );
prototype_ok( &fooey, '$$' );

