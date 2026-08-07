#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B ();
use Template::Stencil;

# refcount of the thing a reference points at
sub rc { B::svref_2object($_[0])->REFCNT }

my $inner = [ 'one', 'two' ];
my $item  = { inner => $inner, name => 'n' };
my $data  = {
    items => [ $item, { inner => ['three'] } ],
    title => 'T',
    map   => { a => 1, b => 2 },
};

my $tmpl = q[{% title %}{% for item in items %}{% set c = loop %}] .
           q[{% for i in item.inner %}{% i %}{% c.index %}{% end %}{% end %}] .
           q[{% for k, v in map %}{% k %}{% v %}{% end %}];

my %before = (
    data  => rc($data),
    items => rc($data->{items}),
    item  => rc($item),
    inner => rc($inner),
    title => rc(\$data->{title}),
);

my $out;
$out = Template::Stencil::_render($tmpl, $data) for 1 .. 50;

is($out, 'Tone0two0three1a1b2', 'render output stable across runs');

is(rc($data),           $before{data},  'data refcount unchanged');
is(rc($data->{items}),  $before{items}, 'items refcount unchanged');
is(rc($item),           $before{item},  'element refcount unchanged');
is(rc($inner),          $before{inner}, 'inner aref refcount unchanged');
is(rc(\$data->{title}), $before{title}, 'scalar refcount unchanged');

# Data content untouched.
is_deeply($data, {
    items => [ { inner => ['one', 'two'], name => 'n' },
               { inner => ['three'] } ],
    title => 'T',
    map   => { a => 1, b => 2 },
}, 'data structure unchanged after 50 renders');

# Error paths unwind cleanly too (strict croak mid-loop).
for (1 .. 20) {
    eval { Template::Stencil::_render(
        '{% for i in items %}{% i.missing.deep %}{% end %}',
        $data, 1) };
}
like($@, qr/undef value/, 'strict error fired');
is(rc($data),          $before{data},  'data refcount stable after errors');
is(rc($data->{items}), $before{items}, 'items refcount stable after errors');

done_testing;
