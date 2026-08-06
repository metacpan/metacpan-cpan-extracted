#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# Variables, dotted paths, array indexing (the draft-test shapes).
is(r('{% name %}', { name => 'x' }), 'x', 'plain variable');
is(r('{% page.header %}', { page => { header => 'H' } }), 'H',
   'dotted path');
is(r('{% page.number[0] %}', { page => { number => [3] } }), '3',
   'indexed path');
is(r('{% a.b[1].c %}', { a => { b => [ {}, { c => 'deep' } ] } }), 'deep',
   'mixed path');

# Escaping of all five specials; raw bypasses.
is(r('{% v %}', { v => q{<b>"it's" & fine</b>} }),
   '&lt;b&gt;&quot;it&#39;s&quot; &amp; fine&lt;/b&gt;',
   'auto-escape all five specials');
is(r('{% raw v %}', { v => '<b>&</b>' }), '<b>&</b>', 'raw opt-out');

# Undef and missing paths render empty (non-strict).
is(r('a{% missing %}b', {}), 'ab', 'missing renders empty');
is(r('a{% u %}b', { u => undef }), 'ab', 'undef renders empty');
is(r('a{% x.y.z %}b', { x => {} }), 'ab', 'missing deep path empty');
is(r('a{% x.y %}b', { x => 'scalar' }), 'ab',
   'deref through non-ref empty');

# Numeric SV stringification.
is(r('{% n %}', { n => 42 }), '42', 'IV');
is(r('{% n %}', { n => 3.5 }), '3.5', 'NV');
is(r('{% n %}', { n => 0 }), '0', "0 prints as '0'");
is(r('{% n %}', { n => '0' }), '0', "'0' prints");
is(r('{% n %}', { n => '' }), '', 'empty string prints nothing');

# Blessed refs cannot be traversed.
{
    my $obj = bless { secret => 1 }, 'Some::Class';
    eval { r('{% o.secret %}', { o => $obj }) };
    like($@, qr/cannot traverse blessed reference in 'o\.secret'/,
         'blessed traversal croaks');
}

# Encoding is the engine's job: by default the output is wire-ready
# UTF-8 bytes (no SvUTF8 flag) whatever the internal form of the
# values; STENCIL_RF_CHARS (0x10, the chars => 1 option) yields a
# flagged character string instead.
{
    my $v = "caf\x{e9} \x{263a}";   # utf8-flagged value
    my $bytes = r('{% v %}', { v => $v });
    ok(!utf8::is_utf8($bytes), 'default output is bytes');
    my $decoded = $bytes;
    utf8::decode($decoded);
    is($decoded, $v, 'bytes are the UTF-8 encoding of the value');

    my $chars = r('{% v %}', { v => $v }, 0x10);
    ok(utf8::is_utf8($chars), 'chars mode output is flagged');
    is($chars, $v, 'chars content intact');
}

# A latin-1-repped value (no utf8 flag, high bytes) is upgraded at
# print so the output is still valid UTF-8.
{
    my $v = "caf\x{e9}";            # stays latin-1 internally
    my $bytes = r('{% v %}', { v => $v });
    my $decoded = $bytes;
    ok(utf8::decode($decoded), 'latin1 value produced valid UTF-8');
    is($decoded, "caf\x{e9}", 'latin1 value upgraded correctly');
}

# UTF-8 template source.
{
    my $tmpl = "\x{263a} {% v %}";
    utf8::upgrade($tmpl);
    my $out = r($tmpl, { v => 'x' }, 0x10);
    is($out, "\x{263a} x", 'utf8 template literal (chars mode)');
    my $bytes = r($tmpl, { v => 'x' });
    ok(!utf8::is_utf8($bytes), 'utf8 source still yields bytes');
    utf8::decode($bytes);
    is($bytes, "\x{263a} x", 'and they decode to the same text');
}

# Comments and literal escape at render level.
is(r('a{%# hidden %}b', {}), 'ab', 'comment gone');
is(r('a{%%}b', {}), 'a{%b', 'literal {% escape');

done_testing;
