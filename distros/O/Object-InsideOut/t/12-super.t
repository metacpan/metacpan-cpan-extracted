use strict;
use warnings;

use Test::More 'tests' => 22;

package Foo; {
    use Object::InsideOut;
    sub me { return __PACKAGE__ }
    sub down { return shift->Xyz::SUPER::me() }
}

package Bar; {
    use Object::InsideOut qw(Foo);
    sub me { return __PACKAGE__ }
    sub up { return shift->SUPER::me() }
}

package Baz; {
    use Object::InsideOut qw(Bar);
    sub me { return __PACKAGE__ }
    sub up { return shift->SUPER::me() }
}

package Xyz; {
    use Object::InsideOut qw(Baz);
    sub me { return __PACKAGE__ }
    sub up { return shift->SUPER::me() }
}


package Bing; {
    sub me { return __PACKAGE__ }
    sub down { return shift->Bong::SUPER::me() }
}

package Bang; {
    our @ISA = qw(Bing);
    sub me { return __PACKAGE__ }
    sub up { return shift->SUPER::me() }
}

package Bong; {
    our @ISA = qw(Bang);
    sub me { return __PACKAGE__ }
    sub up { return shift->SUPER::me() }
}


package main;

is(Foo->can('me')->(), Foo::me()                => q/->can('method')/);
is(Bar->can('me')->(), Bar::me()                => q/->can('method')/);
is(Baz->can('me')->(), Baz::me()                => q/->can('method')/);
is(Xyz->can('me')->(), Xyz::me()                => q/->can('method')/);

ok(! Foo->can('up'),                            => q/No can do/);

is(Bar->can('Xyz::me')->(), Xyz::me()           => q/->can('class::method')/);
is(Foo->can('Baz::me')->(), Baz::me()           => q/->can('class::method')/);

is(Xyz->can('Bar::SUPER::me')->(), Foo::me()    => q/->can('class::SUPER::method')/);
is(Bar->can('Xyz::SUPER::me')->(), Baz::me()    => q/->can('class::SUPER::method')/);

my $code = Bar->can('Xyz::SUPER::down');
is(Bar->$code(), Baz::me()                      => q/->can('class::SUPER::method')/);

is(Foo->can('Bar::SUPER::me')->(), Bar->up()    => q/->can('SUPER::method')/);
is(Baz->can('Xyz::SUPER::me')->(), Xyz->up()    => q/->can('SUPER::method')/);


is(Bing->can('me')->(), Bing::me()              => q/->can('method')/);
is(Bang->can('me')->(), Bang::me()              => q/->can('method')/);
is(Bong->can('me')->(), Bong::me()              => q/->can('method')/);

ok(! Bing->can('up'),                           => q/No can do/);

is(Bang->can('Bong::me')->(), Bong::me()        => q/->can('class::method')/);
is(Bing->can('Bong::me')->(), Bong::me()        => q/->can('class::method')/);

is(Bong->can('Bang::SUPER::me')->(), Bing::me() => q/->can('class::SUPER::method')/);

$code = Bang->can('Bong::SUPER::down');
is(Bong->$code(), Bang::me()                    => q/->can('class::SUPER::method')/);

is(Bing->can('Bang::SUPER::me')->(), Bang->up() => q/->can('SUPER::method')/);
is(Bong->can('Bong::SUPER::me')->(), Bong->up() => q/->can('SUPER::method')/);

exit(0);

# EOF
