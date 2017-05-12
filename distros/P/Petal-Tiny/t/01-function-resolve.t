# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More tests => 23;
BEGIN { use_ok('Petal::Tiny') };
use warnings;
use strict;

package Foo;

sub bar  { "hello" }
sub baz  { "world" }
sub add  { shift(); shift() + shift() }
sub up   { shift; uc (shift()) }
sub self { shift }
sub hash { { up => sub { uc (shift()) } } }

package main;

my $context = { object => bless {}, "Foo" };

is (Petal::Tiny->resolve ('--helloworld', $context), 'helloworld', 'dashdash(resolve)');
is (Petal::Tiny->resolve ('string:helloworld', $context), 'helloworld', 'string:(resolve)');

is (Petal::Tiny->resolve_expression ('--helloworld', $context), 'helloworld', 'dashdash');
is (Petal::Tiny->resolve_expression ('string:helloworld', $context), 'helloworld', 'string:');
is (Petal::Tiny->resolve_expression ('--&amp;', $context), '&amp;amp;', 'dashdash amp');
is (Petal::Tiny->resolve_expression ('string:&amp;', $context), '&amp;amp;', 'string: amp');
is (Petal::Tiny->resolve_expression ('structure --&amp;', $context), '&amp;', 'dashdash structure amp');
is (Petal::Tiny->resolve_expression ('structure string:&amp;', $context), '&amp;', 'string: structure amp');
is (Petal::Tiny->resolve_expression ('fresh --&amp;', $context), '&amp;amp;', 'dashdash fresh amp');
is (Petal::Tiny->resolve_expression ('fresh string:helloworld', $context), 'helloworld', 'string: fresh hello');
is (Petal::Tiny->resolve_expression ('fresh --&amp;', $context), '&amp;amp;', 'dashdash fresh amp');
is (Petal::Tiny->resolve_expression ('fresh string:&amp;', $context), '&amp;amp;', 'string: fresh amp');
is (Petal::Tiny->resolve_expression ('fresh structure --&amp;', $context), '&amp;', 'dashdash structure amp');
is (Petal::Tiny->resolve_expression ('fresh structure string:&amp;', $context), '&amp;', 'string:fresh structure amp');

eval { Petal::Tiny->resolve ("zobbly zobbla", $context) };
like ($@, qr/cannot resolve/, 'resolve junk');

is (Petal::Tiny->resolve_expression ("object/bar", $context), "hello");
is (Petal::Tiny->resolve_expression ("object/baz", $context), "world");
is (Petal::Tiny->resolve_expression ("object/self/baz", $context), "world");
is (Petal::Tiny->resolve_expression ("object/self/self/baz", $context), "world");
is (Petal::Tiny->resolve_expression ("object/self/self/self/add --3 --2", $context), 5);
is (Petal::Tiny->resolve_expression ("object/self/self/self/up --hello", $context), 'HELLO');
is (Petal::Tiny->resolve_expression ("object/hash/up --again", $context), 'AGAIN');
