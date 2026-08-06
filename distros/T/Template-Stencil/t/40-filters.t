#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# upper / lower - ASCII fast path.
is(r('{% v | upper %}', { v => 'abc XYZ 123' }), 'ABC XYZ 123', 'upper');
is(r('{% v | lower %}', { v => 'ABC xyz 123' }), 'abc xyz 123', 'lower');
is(r('{% v | upper %}', { v => '' }), '', 'upper empty');
is(r('{% v | upper %}', { v => 0 }), '0', 'upper numeric');

# upper / lower - UTF-8 path matches core uc/lc (chars mode 0x10 for
# direct string comparison; default mode returns the encoded bytes).
{
    my $u = "caf\x{e9} \x{3b1}\x{3b2} stra\x{df}e";
    utf8::upgrade(my $up = $u);
    is(r('{% v | upper %}', { v => $up }, 0x10), uc($up),
       'utf8 upper eq uc');
    is(r('{% v | lower %}', { v => uc $up }, 0x10), lc(uc $up),
       'utf8 lower eq lc');
    ok(!utf8::is_utf8(r('{% v | upper %}', { v => $up })),
       'default output is bytes');
}

# trim.
is(r('[{% v | trim %}]', { v => "  x y  " }), '[x y]', 'trim both ends');
is(r('[{% v | trim %}]', { v => "\t\n x \r\n" }), '[x]', 'trim mixed ws');
is(r('[{% v | trim %}]', { v => '   ' }), '[]', 'trim all-space');
is(r('[{% v | trim %}]', { v => 'x' }), '[x]', 'trim no-op');

# html (single escape here; interaction rules in t/41).
is(r('{% v | html %}', { v => q{<&>"'} }),
   '&lt;&amp;&gt;&quot;&#39;', 'html escapes all five');

# uri - RFC 3986 unreserved passthrough.
is(r('{% v | uri %}', { v => 'AZaz09-._~' }), 'AZaz09-._~',
   'uri unreserved untouched');
is(r('{% v | uri %}', { v => 'a b&c/d?e=f' }), 'a%20b%26c%2Fd%3Fe%3Df',
   'uri reserved encoded');
{
    utf8::upgrade(my $u = "caf\x{e9}");
    is(r('{% v | uri %}', { v => $u }), 'caf%C3%A9',
       'uri utf8 bytes percent-encoded');
}

# default.
is(r('{% v | default("f") %}', {}), 'f', 'default on missing');
is(r('{% v | default("f") %}', { v => undef }), 'f', 'default on undef');
is(r('{% v | default("f") %}', { v => '' }), 'f', 'default on empty');
is(r('{% v | default("f") %}', { v => '0' }), '0', "default keeps '0'");
is(r('{% v | default("f") %}', { v => 0 }), '0', 'default keeps 0');
is(r('{% v | default(9.5) %}', {}), '9.5', 'numeric default arg');

# Chaining order matters and works.
is(r('{% v | trim | upper %}', { v => ' ab ' }), 'AB', 'trim then upper');
is(r('{% v | upper | trim %}', { v => ' ab ' }), 'AB', 'upper then trim');
is(r('{% v | trim | upper | lower %}', { v => ' Ab ' }), 'ab',
   'three-deep chain');
is(r('{% v | default("x") | upper %}', {}), 'X', 'default feeds chain');

# Filters on dotted paths and in loops.
is(r('{% a.b | upper %}', { a => { b => 'nested' } }),
   'NESTED', 'filter on dotted path');
is(r('{% for i in l %}{% i | upper %};{% end %}', { l => [qw(a b)] }),
   'A;B;', 'filter inside loop');

# Undef passes through non-default filters quietly.
is(r('[{% v | upper %}]', {}), '[]', 'upper on missing is empty');
is(r('[{% v | trim | upper %}]', {}), '[]', 'chain on missing is empty');

done_testing;
