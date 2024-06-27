use 5.022;
use warnings;

use Test::More;
use Scalar::Util 'blessed';

plan tests => 7;

use Multi::Dispatch;

multi foo(OBJ    $obj) { return blessed($obj) }
multi foo(Bar    $obj) { return 'BAR' }          # More specific than OBJ
multi foo(REGEXP $obj) { return 'RX' }

is foo(bless {}, 'Foo'), 'Foo' => 'Object';

is foo(bless {}, 'Bar'), 'BAR' => 'Specific class';

is foo(qr{}),            'RX'  => 'Regexp';

ok !eval { foo({}) }           => 'Hashref';
like $@, qr{\QNo suitable variant for call to multi foo()\E} => '\___ with correct error message';

ok !eval { foo('str') }        => 'String';
like $@, qr{\QNo suitable variant for call to multi foo()\E} => '\___ with correct error message';

done_testing();

