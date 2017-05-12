#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

package Bar;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'rw',
    required => 1,
);

package Baz;
use Moose;
with 'MooseX::Role::Matcher' => { allow_missing_methods => 1 };

has [qw/a b c/] => (
    is       => 'rw',
    required => 1,
);

package Quux;
use Moose;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has bar => (
    is       => 'ro',
    isa      => 'Bar',
    required => 1,
);

has baz => (
    is       => 'ro',
    isa      => 'Baz',
    required => 1,
);

has [qw/a b c/] => (
    is       => 'ro',
    required => 1,
);

package main;
{
    my $bar = Bar->new(a => 1, b => 2, c => 3);
    my $baz = Baz->new(a => 'chess', b => 'go', c => 'nethack');
    my $foo = Foo->new(bar => $bar, baz => $baz,
                       a => 'foo', b => 'bar', c => 'baz');
    ok($foo->match(bar => {
                       a => 1,
                   }),
       'simple submatching works');
    ok(!$foo->match(bar => {
                        b => 1,
                    }),
       'simple submatching works');
    ok($foo->match(bar => {
                       b    => 2,
                       '!c' => sub { $_ > 5 },
                   }),
       'simple submatching works');
    ok($foo->match(a => 'foo',
                   bar => {
                       b => qr/\d/,
                       a => sub { length == 1 },
                   },
                   baz => {
                       c => 'nethack',
                       a => qr/^c.*s$/
                   },
       ),
       'simple submatching works');
}
{
    my $quux = Quux->new;
    my $bar = Bar->new(a => 4, b => 5, c => 6);
    my $baz = Baz->new(a => $bar, b => $quux, c => 'cribbage');
    my $foo = Foo->new(a => 3.14, b => 2.72, c => 1.61,
                       bar => $bar, baz => $baz);
    ok($foo->match(a   => 3.14,
                   bar => {
                       a => 4,
                   },
                   baz => {
                       c => sub { length == 8 },
                       a => {
                           b => 5,
                           c => qr/\d/,
                       },
                   }),
       'deeper submatching works');
    ok(!$foo->match(a   => 3.14,
                    bar => {
                        a => 4,
                    },
                    baz => {
                        d => sub { defined && length == 4 },
                        a => {
                            b => 5,
                            c => qr/\d/,
                        },
                    }),
       'deeper submatching works');
    ok($foo->match(baz => {
                       '!b' => {
                           c => 1,
                       },
                   }),
       'deeper submatching works');
    ok($foo->match(baz => {
                       '!c' => {
                           b => 1,
                       },
                   }),
       'deeper submatching works');
}
{
    my $bar = Bar->new(a => 7, b => 'tmp', c => 9);
    my $baz = Baz->new(a => $bar, b => 'quuux', c => 'tmp');
    my $foo = Foo->new(a => 256, b => 65536, c => 4294967296,
                       bar => $bar, baz => $baz);
    $bar->b($foo);
    $baz->c($baz);
    ok($foo->match(baz => {
                       c => {
                           c => {
                               c => {
                                   c => {
                                       b => 'quuux',
                                   },
                               },
                           },
                       },
                   }),
       'cyclical submatching works');
    ok(!$foo->match(baz => {
                        c => {
                            c => {
                                e => {
                                    c => {
                                        b => 'quuux',
                                    },
                                },
                            },
                        },
                    }),
       'cyclical submatching works');
    ok($foo->match('!b' => sub { $_ % 2 },
                   bar  => {
                       a => 7,
                       b => {
                           a => qr/\d+/,
                           baz => {
                               c => {
                                   a => {
                                       a => 7,
                                       b => $foo
                                   },
                               },
                           },
                       },
                   }),
       'cyclical submatching works');
}
