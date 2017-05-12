#!perl -w
# taken from Data-Util/t/09_paranoia.t
use strict;
use Test::More tests => 25;

#use Scalar::Util;
use Scalar::Util::Instance;

sub is_instance{
    my($obj, $klass) = @_;

    #return Scalar::Util::blessed($obj) && $obj->isa($klass);

    no warnings;

    my $check = Scalar::Util::Instance->generate_for($klass);
    return $check->($obj);
}

BEGIN{
    no warnings;

    sub UNIVERSAL::new{
        bless {} => shift;
    }
    package Foo;
    our @ISA = ('Base');

    sub new{
        bless {} => shift;
    }


    package X;
    package Y;
    package Z;

    package Bar;
    our @ISA = qw(::X main::Y ::main::main::Z);

    my $instance = bless {} => '::main::main::Bar';
    sub instance{ $instance }

    package main::Ax;
    package ::Bx;
    our @ISA = qw(Ax);
    package ::main::main::Cx;
    our @ISA = qw(Bx);
}

my $o = Foo->new();

ok  is_instance($o, 'Foo');
ok  is_instance($o, 'Base');
ok  is_instance($o, 'UNIVERSAL');

@Foo::ISA = ();

ok  is_instance($o, 'Foo');
ok!(is_instance($o, 'Base'));
ok  is_instance($o, 'UNIVERSAL');

ok is_instance($o, '::Foo');
ok is_instance($o, 'main::Foo');
ok is_instance($o, 'main::main::Foo');
ok!is_instance($o, '::::Foo');
ok!is_instance($o, 'Fooo');
ok!is_instance($o, 'FoO');
ok!is_instance($o, 'foo');
ok!is_instance($o, 'mai');
ok!is_instance($o, 'UNIVERSA');


$o = Bar->instance;

ok is_instance($o, 'Bar');
ok is_instance($o, 'X');
ok is_instance($o, 'Y');
ok is_instance($o, 'Z');
ok is_instance($o, '::Z');

ok!is_instance($o, 'main');
ok!is_instance($o, 'main::');


ok is_instance(Cx->new, 'Ax');
ok is_instance(Cx->new, 'Bx');
ok is_instance(Cx->new, 'Cx');
