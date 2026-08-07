#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# Basic array loop.
is(r('{% for i in items %}{% i %};{% end %}', { items => [qw(a b c)] }),
   'a;b;c;', 'array loop');

# All loop fields, checked at first / middle / last.
{
    my $t = '{% for i in items %}'
          . '[{% loop.index %},{% loop.index1 %},{% loop.size %},'
          . '{% if loop.first %}F{% end %}{% if loop.last %}L{% end %},'
          . '{% if loop.even %}E{% else %}O{% end %}]'
          . '{% end %}';
    is(r($t, { items => [qw(x y z)] }),
       '[0,1,3,F,O][1,2,3,,E][2,3,3,L,O]',
       'loop metadata across iterations');
}

# Nested loops: loop is the innermost.
is(r('{% for a in aa %}{% for b in bb %}{% loop.index %}{% end %}|{% end %}',
     { aa => [1, 2], bb => [qw(p q)] }),
   '01|01|', 'inner loop shadows');

# Hash iteration: sorted by default, key/value bound.
is(r('{% for k, v in h %}{% k %}={% v %};{% end %}',
     { h => { banana => 2, apple => 1, cherry => 3 } }),
   'apple=1;banana=2;cherry=3;', 'sorted hash loop');
is(r('{% for k, v in h %}{% loop.key %}{% end %}',
     { h => { a => 1 } }), 'a', 'loop.key');

# Unsorted flag (order unspecified - assert content, not order).
{
    my $out = r('{% for k, v in h %}{% k %};{% end %}',
                { h => { a => 1, b => 2 } }, 2); # STENCIL_RF_NO_SORT_KEYS
    is(join(';', sort split /;/, $out), 'a;b', 'unsorted still complete');
}

# Empty / undef iterables render nothing.
is(r('x{% for i in items %}!{% end %}y', { items => [] }), 'xy',
   'empty array');
is(r('x{% for i in items %}!{% end %}y', {}), 'xy', 'missing iterable');
is(r('x{% for k, v in h %}!{% end %}y', { h => {} }), 'xy', 'empty hash');

# Type errors.
{
    eval { r('{% for i in v %}{% end %}', { v => 'scalar' }) };
    like($@, qr/'v' is not an array reference/, 'scalar in for');
    eval { r('{% for i in v %}{% end %}', { v => { a => 1 } }) };
    like($@, qr/'v' is not an array reference/, 'hashref needs k,v form');
    eval { r('{% for k, v in a %}{% end %}', { a => [1] }) };
    like($@, qr/'a' is not a hash reference/, 'arrayref with k,v form');
}

# Loop variables shadow data; data is restored after the loop.
is(r('{% x %}|{% for x in items %}{% x %}{% end %}|{% x %}',
     { x => 'outer', items => ['in'] }),
   'outer|in|outer', 'loop var shadows and unshadows');

# Iterating hash values that are structures.
is(r('{% for item in items %}{% item.name %};{% end %}',
     { items => [ { name => 'a' }, { name => 'b' } ] }),
   'a;b;', 'element paths');

# Undef elements render empty but still iterate.
is(r('{% for i in items %}[{% i %}]{% end %}', { items => [undef, 'x'] }),
   '[][x]', 'undef element');

# 10k iterations complete correctly.
{
    my $out = r('{% for i in items %}{% i %}{% end %}',
                { items => [ (1) x 10000 ] });
    is(length $out, 10000, '10k iterations');
}

# The full draft-test nested scenario.
{
    my $t = q[{% for item in items %}{% set item_loop = loop %}{% for inner in item.inner %}<div {% if loop.first %}class="first"{% else %}class="other"{% end %} data-item-loop="{% item_loop.index %}" data-inner-loop="{% loop.index %}">{% inner %}</div>{% end %}{% if loop.last %}<p>{% loop.index %} last</p>{% end %}{% end %}];
    my $out = r($t, { items => [
        { inner => [qw(one two)] },
        { inner => [qw(three)] },
    ] });
    is($out,
       '<div class="first" data-item-loop="0" data-inner-loop="0">one</div>'
     . '<div class="other" data-item-loop="0" data-inner-loop="1">two</div>'
     . '<div class="first" data-item-loop="1" data-inner-loop="0">three</div>'
     . '<p>1 last</p>',
       'draft-test nested loop scenario');
}

done_testing;
