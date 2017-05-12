use lib (-e 't' ? 't' : 'test'), 'inc';
use Test::More tests => 1;

eval <<'...';
package Foo;
use base 'NonSpiffy';
...

is $@, '';
