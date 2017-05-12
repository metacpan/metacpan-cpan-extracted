package t::usage;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use constant MIN_SCALAR_CONSTANT_PERL_VERSION => v5.10.0;

plan tests => 16;

use Symbol::Get ();

sub _perl_supports_getting_scalar_constant_ref { return $^V ge MIN_SCALAR_CONSTANT_PERL_VERSION }

#----------------------------------------------------------------------

package t::Foo::Bar;

use Test::More ();
use Test::Deep;
#use Test::Exception;

use constant my_const => 'haha';
use constant my_list => qw( ha ha );

our $thing = 'thing';

our @list = qw( a b c );

our %hash = ( a => 1, b => 2 );

sub my_code { }
#----------------------------------------------------------------------

package t::usage;

is(
    Symbol::Get::get('$t::Foo::Bar::thing'),
    \$t::Foo::Bar::thing,
    'scalar',
);

is(
    Symbol::Get::get('@t::Foo::Bar::list'),
    \@t::Foo::Bar::list,
    'list',
);

is(
    Symbol::Get::get('%t::Foo::Bar::hash'),
    \%t::Foo::Bar::hash,
    'hash',
);

is(
    Symbol::Get::get('%t::Foo::Bar::'),
    \%t::Foo::Bar::,
    'symbol table hash',
);

is(
    Symbol::Get::get('&t::Foo::Bar::my_code'),
    \&t::Foo::Bar::my_code,
    'code',
);

is(
    Symbol::Get::get('&t::Foo::Bar::i_am_not_there'),
    undef,
    'get() returns undef on an unknown variable name',
);

#----------------------------------------------------------------------
#SKIP: {
#    skip 'Needs >= v5.10', 1 if !_perl_supports_getting_scalar_constant_ref();
#
#    is(
#        Symbol::Get::get('t::Foo::Bar::my_const'),
#        $t::Foo::Bar::{'my_const'},
#        'constant (scalar)',
#    );
#}
#
#is(
#    Symbol::Get::copy_constant('t::Foo::Bar::my_const'),
#    t::Foo::Bar::my_const(),
#    'copy_constant (scalar, no package)',
#);
#
#SKIP: {
#    skip 'Needs >= v5.20', 1 if !Symbol::Get::_perl_supports_getting_list_constant_ref();
#
#    is(
#        Symbol::Get::get('t::Foo::Bar::my_list'),
#        $t::Foo::Bar::{'my_list'},
#        'constant (array)',
#    );
#}
#
#throws_ok(
#    sub { diag explain Symbol::Get::get('t::Foo::Bar::list') },
#    qr<t::Foo::Bar::list>,
#    'constant die()s if fed a non-constant',
#);

is_deeply(
    [ Symbol::Get::copy_constant('t::Foo::Bar::my_list') ],
    [ t::Foo::Bar::my_list() ],
    'copy_constant (list, no package)',
);

throws_ok(
    sub { my $v = Symbol::Get::copy_constant('t::Foo::Bar::my_list') },
    'Call::Context::X',
    'copy_constant() demands list context for a list',
);

#----------------------------------------------------------------------

#cmp_deeply(
#    [ Symbol::Get::get_names('t::Foo::Bar') ],
#    superbagof( qw( thing list hash my_code my_const my_list ) ),
#    'get_names()',
#) or diag explain [ Symbol::Get::get_names('t::Foo::Bar') ];
#
#throws_ok(
#    sub { () = Symbol::Get::get_names('t::Foo::Bar::NOT_THERE') },
#    qr<t::Foo::Bar::NOT_THERE>,
#    'get_names() throws on an unknown package name',
#);

#----------------------------------------------------------------------

package t::Foo::Bar;

use Test::More;
use Test::Exception;

is(
    Symbol::Get::get('$thing'),
    \$t::Foo::Bar::thing,
    'scalar, no package',
);

is(
    Symbol::Get::get('@list'),
    \@t::Foo::Bar::list,
    'list, no package',
);

is(
    Symbol::Get::get('%hash'),
    \%t::Foo::Bar::hash,
    'hash, no package',
);

is(
    Symbol::Get::get('&my_code'),
    \&t::Foo::Bar::my_code,
    'code, no package',
);

cmp_deeply(
    [ Symbol::Get::get_names() ],
    superbagof( qw( thing list hash my_code my_const my_list ) ),
    'get_names(), no package',
) or diag explain [ Symbol::Get::get_names('t::Foo::Bar') ];

#SKIP: {
#    Test::More::skip 'Needs >= v5.10', 1 if !t::usage::_perl_supports_getting_scalar_constant_ref();
#
#    is(
#        Symbol::Get::get('my_const'),
#        $t::Foo::Bar::{'my_const'},
#        'constant (scalar, no package)',
#    );
#}

is(
    Symbol::Get::copy_constant('my_const'),
    t::Foo::Bar::my_const(),
    'copy_constant (scalar, no package)',
);

#SKIP: {
#    skip 'Needs >= v5.20', 1 if !Symbol::Get::_perl_supports_getting_list_constant_ref();
#
#    is(
#        Symbol::Get::get('my_list'),
#        $t::Foo::Bar::{'my_list'},
#        'constant (array, no package)',
#    );
#}

is_deeply(
    [ Symbol::Get::copy_constant('my_list') ],
    [ t::Foo::Bar::my_list() ],
    'copy_constant (list, no package)',
);

throws_ok(
    sub { my $v = Symbol::Get::copy_constant('my_list') },
    'Call::Context::X',
    'copy_constant() demands list context for a list',
);

1;
