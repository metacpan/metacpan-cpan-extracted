#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# fmt - sprintf with exactly one conversion, validated when the template
# compiles, executed in C. The number-formatting filter that used to need
# a Perl coderef.

# ---- conversions -------------------------------------------------------------
is(r(q({% v | fmt('%.2f') %}),  { v => 1.5 }),        '1.50',    'f');
is(r(q({% v | fmt('%.2f') %}),  { v => '3.14159' }),  '3.14',    'f from string');
is(r(q({% v | fmt('%e') %}),    { v => 1.5 }),        '1.500000e+00', 'e');
is(r(q({% v | fmt('%.1E') %}),  { v => 1500 }),       '1.5E+03', 'E');
is(r(q({% v | fmt('%g') %}),    { v => 0.00001 }),    '1e-05',   'g');
is(r(q({% v | fmt('%G') %}),    { v => 0.00001 }),    '1E-05',   'G');
is(r(q({% v | fmt('%d') %}),    { v => 42.9 }),       '42',      'd truncates');
is(r(q({% v | fmt('%i') %}),    { v => -7 }),         '-7',      'i');
is(r(q({% v | fmt('%u') %}),    { v => 42 }),         '42',      'u');
is(r(q({% v | fmt('%o') %}),    { v => 8 }),          '10',      'o');
is(r(q({% v | fmt('%x') %}),    { v => 3735928559 }), 'deadbeef', 'x');
is(r(q({% v | fmt('%X') %}),    { v => 255 }),        'FF',      'X');
is(r(q({% v | fmt('%s') %}),    { v => 'hi' }),       'hi',      's');

# ---- flags, width, precision -------------------------------------------------
is(r(q({% v | fmt('%05d') %}),   { v => 42 }),  '00042',   'zero pad');
is(r(q({% v | fmt('%-5d|') %}),  { v => 42 }),  '42   |',  'left align');
is(r(q({% v | fmt('%+d') %}),    { v => 42 }),  '+42',     'plus flag');
is(r(q({% v | fmt('%#x') %}),    { v => 255 }), '0xff',    'alt form');
is(r(q({% v | fmt('%8.2f') %}),  { v => 3.14159 }), '    3.14', 'width + prec');
is(r(q({% v | fmt('%.3s') %}),   { v => 'hello' }), 'hel',  's precision');
is(r(q({% v | fmt('%10s') %}),   { v => 'hi' }), '        hi', 's width');

# ---- literal text around the conversion --------------------------------------
is(r(q({% v | fmt('$%.2f') %}),        { v => 1.5 }), '$1.50', 'prefix');
is(r(q({% v | fmt('%d items') %}),     { v => 3 }),   '3 items', 'suffix');
is(r(q({% v | fmt('100%% is %d') %}),  { v => 5 }),   '100% is 5', '%% literal');

# ---- value handling ----------------------------------------------------------
is(r(q({% v | fmt('%.2f') %}), { v => undef }), '', 'undef passes through');
is(r(q(<{% v | fmt('%d') %}>), {}),             '<>', 'missing passes through');
is(r(q({% v | fmt('%.2f') %}), { v => 0 }),     '0.00', 'zero formats');

# big integers keep their width (the render splices perl's own IV/UV
# length modifiers into the format). IV_MAX, not a fixed literal: on a
# perl without 64-bit integers 2**53 is an NV that no %d can represent,
# and SvIV clamps it to UV_MAX - which reads back as -1.
my $iv_max = ~0 >> 1;
is(r(q({% v | fmt('%d') %}), { v => $iv_max }), sprintf('%d', $iv_max),
   'IV width');
is(r(q({% v | fmt('%.2f') %}), { v => 1/3 }), sprintf('%.2f', 1/3),
   'NV width');

# ---- the loop shape it exists for --------------------------------------------
is(r(q({% for p in prices %}{% p | fmt('%.2f') %},{% end %}),
     { prices => [ 1, 2.5, 3.333 ] }),
   '1.00,2.50,3.33,', 'per-row formatting');

# ---- escaping interplay ------------------------------------------------------
# fmt output is not pre-escaped: auto_escape still applies to it
is(r(q({% v | fmt('<%s>') %}), { v => 'a&b' }, 0x1),
   '&lt;a&amp;b&gt;', 'auto_escape escapes fmt output');
is(r(q({% v | fmt('%s') | html %}), { v => '<b>' }), '&lt;b&gt;',
   'chains into html');
is(r(q({% v | upper | fmt('[%s]') %}), { v => 'hi' }), '[HI]',
   'chains after another filter');

# ---- utf8 --------------------------------------------------------------------
{
    utf8::upgrade(my $t = qq(\x{20ac}{% v | fmt('%.2f') %}));  # euro literal
    my $out = r($t, { v => 1.5 }, 0x10);
    is($out, "\x{20ac}1.50", 'utf8 literal around the conversion');
}
{
    utf8::upgrade(my $u = "caf\x{e9} bar");
    my $out = r(q({% v | fmt('%s!') %}), { v => $u }, 0x10);
    is($out, "caf\x{e9} bar!", 'utf8 %s value');
    # byte-counted precision may not leave half a character behind
    $out = r(q({% v | fmt('%.4s') %}), { v => $u }, 0x10);
    is($out, 'caf', 'precision strips an incomplete utf8 sequence');
}

# ---- compile-time rejection --------------------------------------------------
for my $case (
    [ q({% v | fmt %}),                  qr/needs a quoted format/ ],
    [ q({% v | fmt(2) %}),               qr/needs a quoted format/ ],
    [ q({% v | fmt('plain') %}),         qr/needs one % conversion/ ],
    [ q({% v | fmt('%d and %s') %}),     qr/only one conversion/ ],
    [ q({% v | fmt('%*d') %}),           qr/'\*' is not allowed/ ],
    [ q({% v | fmt('%n') %}),            qr/conversion must be one of/ ],
    [ q({% v | fmt('%ld') %}),           qr/conversion must be one of/ ],
    [ q({% v | fmt('%hd') %}),           qr/conversion must be one of/ ],
    [ q({% v | fmt('%99999d') %}),       qr/width is too large/ ],
    [ q({% v | fmt('%.99999f') %}),      qr/precision is too large/ ],
    [ q({% v | fmt('tail%') %}),         qr/ends inside a conversion/ ],
) {
    my ($tmpl, $want) = @$case;
    my $err = '';
    eval { r($tmpl, { v => 1 }) } or $err = $@;
    like($err, $want, "rejected: $tmpl");
}
{
    my $long = '%d' . ('x' x 60);
    my $err = '';
    eval { r(qq({% v | fmt('$long') %}), { v => 1 }) } or $err = $@;
    like($err, qr/format is too long/, 'rejected: overlong format');
}

done_testing;
