use Test::More tests => 2;
use strict;
use Foo;

ok 1;

ok( Foo::ok() eq 'ok' );

__END__