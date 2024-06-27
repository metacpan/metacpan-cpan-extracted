use v5.22;
use warnings;
use experimental 'signatures';

use Multi::Dispatch;

package Basic {
    sub foo (@args) { 'Basic' }
}

package Interim {
    use base 'Basic';
    multimethod foo :common ($x, $y) { 'Int_xy' }
    multimethod foo :common (%args)  { $class->next::method(%args); }
}

package Der {
    use base 'Interim';
    use mro;
    multimethod foo :common ($x)     { 'Der_x' }
}

use Test::More;

plan tests => 3;

is(  Der->foo('x'),            'Der_x'  =>  'Derived X MD' );
is(  Der->foo('x', 'y'),       'Int_xy' =>  'Derived XY MD' );
is(  Der->foo(a=>'x', b=>'y'), 'Basic'  =>  'Redispatched SD' );

done_testing();

