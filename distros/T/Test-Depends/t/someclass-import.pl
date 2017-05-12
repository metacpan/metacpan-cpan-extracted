
use Test::Depends [ SomeClass => $ARGV[0] ] ;

use Test::More tests => 1;

is(&somefunc, "func-y", "somefunc sure is func-y");
