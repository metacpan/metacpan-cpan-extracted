
use strict;
use warnings;

use Test::More tests => 6;

{
    package My;

    our $VERSION = '0.1';
    our @ISA = ();
    sub foo { return 1; }
    our $regex = qr/foo/;

    use Symbol::Global::Name;
    our %res;
    $res{'scalar'} = Symbol::Global::Name->find( \$VERSION );
    $res{'sub'} = Symbol::Global::Name->find( \&foo );
    $res{'array'} = Symbol::Global::Name->find( \@ISA );
    $res{'hash'} = Symbol::Global::Name->find( \%ENV );
    $res{'regex'} = Symbol::Global::Name->find( \$regex );
}

{
    package Foo::Bar;
    our $baz = 'x';
}

package main;
is($My::res{'scalar'}, '$My::VERSION', 'found name');
is($My::res{'sub'}, '&My::foo', 'found name');
is($My::res{'array'}, '@My::ISA', 'found name');
is($My::res{'hash'}, '%main::ENV', 'found name');
is($My::res{'regex'}, '$My::regex', 'found name');

is(Symbol::Global::Name->find(\$Foo::Bar::baz), '$Foo::Bar::baz', 'found name');
