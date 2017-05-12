use strict;
use Test::More skip_all => 'Mouse upstream needs to sort out composition';

use Test::More tests => 2;

{
    package Rollo;
    use MouseX::POE::Role;

    event foo => sub {
        ::fail('not overridden');
    };
}

{
    package Foo;
    use MouseX::POE;
    with 'Rollo';

    sub START {
        ::pass('START');
        $_[KERNEL]->yield('foo');
    }

    event foo => sub {
        ::pass('overridden foo');
    };
}

Foo->new;
POE::Kernel->run;
