#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';
}

my $foo = Foo->new;
ok(
    $foo->does('MooseX::Role::Loggable'),
    'Role consumptions works',
);

my @attributes = qw/ debug logger_facility logger_ident logger /;
my @methods    = qw/ log_to_file log_to_stdout log_to_stderr /;

ok(
    can_ok( $foo, @attributes ),
    'Provided attributes composed',
);

ok(
    can_ok( $foo, @methods ),
    'Provided methods composed',
);

