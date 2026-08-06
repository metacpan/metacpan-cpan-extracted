#!perl
use 5.016;
use strict;
use warnings;
use utf8;
use Test::More;
use Template::Stencil;

# Dedicated multibyte coverage under the engine-owns-encoding rules:
# output is always valid UTF-8 bytes by default; chars => 1 gives
# flagged strings.

my $bytes = Template::Stencil->new;
my $chars = Template::Stencil->new(chars => 1);

sub dec { my $b = shift; utf8::decode($b) or die 'invalid utf8'; $b }

# UTF-8 template source (this file is `use utf8`).
{
    my $tmpl = 'héllo {% name %} ☃';
    is(dec($bytes->render($tmpl, { name => 'wörld' })),
       'héllo wörld ☃', 'utf8 source + utf8 data');
    is($chars->render($tmpl, { name => 'wörld' }),
       'héllo wörld ☃', 'chars mode direct compare');
}

# Mixed internal representations of the same text agree.
{
    my $l1 = "caf\x{e9}";                       # latin-1 repped
    my $up = $l1; utf8::upgrade($up);           # utf8 repped
    is($bytes->render('{% v %}', { v => $l1 }),
       $bytes->render('{% v %}', { v => $up }),
       'latin1 and utf8 reps render identical bytes');
}

# Escaping never corrupts multibyte sequences.
{
    my $v = '<б>&"я"';
    my $out = dec($bytes->render('{% v %}', { v => $v }));
    is($out, '&lt;б&gt;&amp;&quot;я&quot;', 'escape around multibyte');
}

# Filters on multibyte (chars mode for direct eq).
is($chars->render('{% v | upper %}', { v => 'straße αβγ' }),
   uc('straße αβγ'), 'upper matches uc');
is($chars->render('{% v | lower %}', { v => 'STRASSE ΑΒΓ' }),
   lc('STRASSE ΑΒΓ'), 'lower matches lc');
is($chars->render('{% v | trim %}', { v => "  ☃  " }), '☃',
   'trim keeps multibyte');
is(dec($bytes->render('{% v | uri %}', { v => 'café' })),
   'caf%C3%A9', 'uri percent-encodes utf8 bytes');

# Multibyte in every structural position: keys, paths, includes are
# byte-based; hash keys with multibyte sort bytewise but render intact.
{
    my $out = dec($bytes->render('{% for k, v in h %}{% k %}={% v %};{% end %}',
                                 { h => { 'é' => 1, 'a' => 2 } }));
    is($out, 'a=2;é=1;', 'multibyte hash keys iterate and render');
}

# String comparisons follow perl semantics on flagged strings.
is($chars->render(q[{% if v eq 'é' %}y{% else %}n{% end %}],
                  { v => 'é' }), 'y', 'multibyte eq');

# Content-Length correctness: byte length, not char length.
{
    my $out = $bytes->render('{% v %}', { v => '☃' });
    is(length $out, 3, 'snowman is three bytes');
}

done_testing;
