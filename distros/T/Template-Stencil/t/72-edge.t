#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

my $s = Template::Stencil->new;
sub r { $s->render(@_) }

# Falsy-but-real values render and compare correctly.
is(r('[{% v %}]', { v => 0 }),   '[0]', '0 renders');
is(r('[{% v %}]', { v => '0' }), '[0]', "'0' renders");
is(r('[{% v %}]', { v => '' }),  '[]',  "'' renders empty");
is(r('{% if defined(v) %}d{% end %}{% if v %}t{% else %}f{% end %}',
     { v => 0 }), 'df', '0 defined but false');

# Path depth at the limit.
{
    my $deep = { b => { c => { d => { e => { f => { g => { h => 'deep' } } } } } } };
    is(r('{% a.b.c.d.e.f.g.h %}', { a => $deep }), 'deep',
       '8-segment path resolves');
}

# Large loop completes with correct metadata at the far end.
{
    my $out = r('{% for i in l %}{% if loop.last %}{% loop.index1 %}{% end %}{% end %}',
                { l => [ (0) x 10000 ] });
    is($out, '10000', '10k-iteration loop');
}

# Tiny templates.
is(r('', {}), '', 'empty template');
is(r('x', {}), 'x', 'one-byte template');
is(r('{% v %}', { v => 'only' }), 'only', 'template that is one tag');

# A giant single literal (crosses every SIMD width and the LONG path).
{
    my $lit = join '', map { chr(97 + $_ % 26) } 1 .. 100_000;
    is(r($lit, {}), $lit, '100 KB pure literal');
}

# Injection safety: values containing template syntax are NEVER
# re-parsed - they are data.
{
    my $evil = q[{% for x in secrets %}{% x %}{% end %}{% include /etc/passwd %}{%%}];
    my $out = r('[{% v %}]', { v => $evil, secrets => ['s3cr3t'] });
    unlike($out, qr/s3cr3t/, 'value not evaluated');
    like($out, qr/\Q{%\E for x in secrets/, 'tags rendered as text');
    is(r('[{% raw v %}]', { v => $evil, secrets => ['x'] }),
       "[$evil]", 'raw value verbatim, still not evaluated');
}

# Keys that look like keywords are fine as data.
is(r('{% for k, v in h %}{% k %}{% end %}',
     { h => { if => 1, end => 2, loop => 3 } }),
   'endifloop', 'keyword-named hash keys iterate');

# Set-bind churn in a long loop stays bounded (per-iteration pops).
{
    my $out = r('{% for i in l %}{% set a = i %}{% set b = a %}{% end %}{% b %}',
                { l => [ 1 .. 5000 ] });
    is($out, '', 'binds popped every iteration, none leak out');
}

# Deep block nesting at the compiler limit renders.
{
    my $t = ('{% if 1 %}' x 64) . 'ok' . ('{% end %}' x 64);
    is(r($t, {}), 'ok', '64-deep nesting renders');
}

# Whitespace-insensitive tags.
is(r("{%v%}|{%  v  %}|{%\n\tv\n%}", { v => 'w' }), 'w|w|w',
   'delimiter whitespace variants');

done_testing;
