#!perl -w
use strict;
use Test::More tests => 28;
use Test::Exception;

use Scalar::Util::Instance ();

Scalar::Util::Instance->generate_for('Foo',       'is_a_foo');
Scalar::Util::Instance->generate_for('Bar',       'is_a_bar');
Scalar::Util::Instance->generate_for('Baz',       'is_a_baz');
Scalar::Util::Instance->generate_for('HASH',      'is_a_hash');
Scalar::Util::Instance->generate_for('Broken',    'is_a_broken');
Scalar::Util::Instance->generate_for('UNIVERSAL', 'is_a_universal');
Scalar::Util::Instance->generate_for('AL',        'is_an_al');


BEGIN{
    package Foo;
    sub new{ bless {}, shift }

    package Bar;
    our @ISA = qw(Foo);

    package Foo_or_Bar;
    our @ISA = qw(Foo);

    package Baz;
    sub new{ bless {}, shift }
    sub isa{
        my($x, $y) = @_;
        return $y eq 'Foo';
    }

    package Broken;
    sub isa; # pre-declaration only

    package AL;
    sub new{ bless {}, shift }
    sub DESTROY{}
    sub isa;

    sub AUTOLOAD{
        #our $AUTOLOAD; ::diag "$AUTOLOAD(@_)";
        1;
    }

    package AL_stubonly;

    sub new{ bless{}, shift; }
    sub DESTROY{};
    sub isa;

    sub AUTOLOAD;

}

ok  is_a_foo(Foo->new);
ok !is_a_bar(Foo->new);
ok !is_a_baz(Foo->new);
ok  is_a_universal(Foo->new);

ok  is_a_foo(Bar->new);
ok  is_a_bar(Bar->new);
ok !is_a_baz(Bar->new);
ok  is_a_universal(Bar->new);

ok  is_a_foo(Baz->new);
ok !is_a_bar(Baz->new);
ok !is_a_baz(Baz->new);

ok is_a_foo(Foo_or_Bar->new);
ok!is_a_bar(Foo_or_Bar->new);

@Foo_or_Bar::ISA = qw(Bar);
ok is_a_bar(Foo_or_Bar->new), '@ISA changed at run-time';

@Foo_or_Bar::ISA = qw(Foo);
ok is_a_foo(Foo_or_Bar->new);
ok!is_a_bar(Foo_or_Bar->new);

# no object reference

ok !is_a_foo('Foo');
ok !is_a_foo(undef);
ok !is_a_foo({});

ok !is_a_hash({});

dies_ok{ is_a_broken(Broken->new())  };

ok is_an_al(AL->new);
ok is_a_foo(AL->new);

dies_ok { is_an_al(AL_stubonly->new) };

throws_ok{
    is_a_foo();
} qr/Not enough arguments/;

throws_ok{
    is_a_foo(1, 2);
} qr/Too many arguments/;


throws_ok{
    is_a_universal();
} qr/Not enough arguments/;

throws_ok{
    is_a_universal(1, 2);
} qr/Too many arguments/;

