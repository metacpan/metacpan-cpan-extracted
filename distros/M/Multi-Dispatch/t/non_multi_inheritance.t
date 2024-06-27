use 5.022;
use warnings;
use strict;

use Test::More;

plan tests => 10;

use Multi::Dispatch;

package Basic {
    sub foo { return 'Basic foo' }
}

package Interim {
    use base 'Basic';

    multimethod foo :common ($x, $y) { return 'Interim foo'; }
    multimethod bar :common ($x, $y) { return 'Interim bar'; }
}

package Outerim {
    use base 'Interim';

    sub foo { return 'Outerim foo' }
}

package Derived {
    use base 'Outerim';

    multimethod foo :common ($x) { return 'Derived foo'; }
    multimethod bar :common ($x) { return 'Derived bar'; }
}

is(  Derived->foo(1),     'Derived foo'  =>  'Derived: Derived foo' );
is(  Derived->foo(1,2),   'Interim foo'  =>  'Derived: Interim foo' );
is(  Derived->foo(1,2,3), 'Outerim foo'  =>  'Derived: Outerim foo' );

is(  Interim->foo(1),     'Basic foo'    =>  'Interim: Basic foo' );
is(  Interim->foo(1,2),   'Interim foo'  =>  'Interim: Interim foo' );
is(  Interim->foo(1,2,3), 'Basic foo'    =>  'Interim: Basic foo' );

is(   Derived->bar(1),     'Derived bar'  =>  'Derived: Derived bar' );
is(   Derived->bar(1,2),   'Interim bar'  =>  'Derived: Interim bar' );
ok !eval{ Derived->bar(1,2,3) }           =>  'Derived: no suitable bar';
like $@, qr/No suitable variant/          =>  '        \...with correct error';

done_testing();
