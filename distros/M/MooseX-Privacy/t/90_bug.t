use strict;
use warnings;

use Test::More;
use Test::Exception;

package Foo;
use Moose;
use MooseX::Privacy;

has foo => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_foo',
    clearer   => '_clear_foo',
    lazy      => 1,
    default   => 'BooM!',
    traits    => [qw/Private/],
);

has bar => (
    is     => 'ro',
    isa    => 'Str',
    traits => [qw/Private/],
);

sub public_foo { shift->foo }
sub public_foo_clearer { shift->_clear_foo }
sub public_foo_predicate { shift->has_foo ? return 1 : return 0 }

package main;

my $o = Foo->new();
dies_ok { $o->foo };
dies_ok { $o->bar };
dies_ok { $o->has_foo };
dies_ok { $o->_clear_foo };

is $o->public_foo, 'BooM!';
ok $o->public_foo_predicate;
ok $o->public_foo_clearer;
ok !$o->public_foo_predicate;

done_testing;
