#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

# The language, spec-by-example: one assertion per syntax rule, in the
# order the documentation presents them. Broader edge cases live in
# t/2x-t/7x; this file is the readable reference.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub put {
    my ($name, $content) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $content;
    close $fh;
}

my $s = Template::Stencil->new(
    template_dir => $dir,
    filters      => { shout => sub { "$_[0]!" } },
);
sub r { $s->render(@_) }

# ---- output tags -----------------------------------------------------

note 'output tags';
is(r('{% name %}', { name => 'v' }), 'v', 'variable');
is(r('{% a.b %}', { a => { b => 'v' } }), 'v', 'dotted path');
is(r('{% a[1] %}', { a => [ 'x', 'y' ] }), 'y', 'array index');
is(r('{% a.b[0].c %}', { a => { b => [ { c => 'v' } ] } }), 'v',
   'mixed dots and indices');
is(r('{% a[0][1] %}', { a => [ [ 'x', 'y' ] ] }), 'y', 'chained indices');
is(r('{%name%}', { name => 'v' }), 'v', 'no delimiter whitespace');
is(r("{%  name\t%}", { name => 'v' }), 'v', 'any delimiter whitespace');

note 'escaping';
is(r('{% v %}', { v => q{<>&"'} }), '&lt;&gt;&amp;&quot;&#39;',
   'all five specials escaped');
is(r('{% raw v %}', { v => q{<>&"'} }), q{<>&"'}, 'raw bypasses');
is(r('[{% v %}]', {}), '[]', 'missing renders empty');
is(r('[{% v %}]', { v => undef }), '[]', 'undef renders empty');

# ---- filters ---------------------------------------------------------

note 'filters';
is(r('{% v | upper %}', { v => 'ab' }), 'AB', 'upper');
is(r('{% v | lower %}', { v => 'AB' }), 'ab', 'lower');
is(r('[{% v | trim %}]', { v => ' a ' }), '[a]', 'trim');
is(r('{% v | html %}', { v => '<b>' }), '&lt;b&gt;',
   'html escapes exactly once');
is(r('{% v | uri %}', { v => 'a b' }), 'a%20b', 'uri');
is(r('{% v | default("d") %}', {}), 'd', 'default string arg');
is(r('{% v | default(7) %}', {}), '7', 'default numeric arg');
is(r('{% v | trim | upper %}', { v => ' a ' }), 'A',
   'filters chain left to right');
is(r('{% v | shout %}', { v => 'hi' }), 'hi!', 'user filter');
is(r('{% v | shout | upper %}', { v => 'hi' }), 'HI!',
   'user and builtin mix');
is(r('{% v | html | upper %}', { v => '<b>' }), '&amp;LT;B&amp;GT;',
   'post-html filter re-escapes');
is(r('{% raw v | upper %}', { v => '<b>' }), '<B>', 'raw with filters');

# ---- conditionals and expressions ------------------------------------

note 'conditionals';
is(r('{% if v %}T{% end %}', { v => 1 }), 'T', 'if');
is(r('{% if v %}T{% else %}F{% end %}', { v => 0 }), 'F', 'else');
is(r('{% if a %}1{% elsif b %}2{% else %}3{% end %}', { b => 1 }), '2',
   'elsif');
is(r('{% unless v %}T{% end %}', { v => 0 }), 'T', 'unless');

note 'truthiness';
is(r('{% if v %}T{% else %}F{% end %}', { v => 'x' }),   'T', 'string true');
is(r('{% if v %}T{% else %}F{% end %}', { v => 0 }),     'F', '0 false');
is(r('{% if v %}T{% else %}F{% end %}', { v => '0' }),   'F', "'0' false");
is(r('{% if v %}T{% else %}F{% end %}', { v => '' }),    'F', "'' false");
is(r('{% if v %}T{% else %}F{% end %}', { v => undef }), 'F', 'undef false');
is(r('{% if v %}T{% else %}F{% end %}', { v => [] }),    'F',
   'empty arrayref false (extension)');
is(r('{% if v %}T{% else %}F{% end %}', { v => {} }),    'F',
   'empty hashref false (extension)');
is(r('{% if v %}T{% else %}F{% end %}', { v => [0] }),   'T',
   'non-empty arrayref true');

note 'comparisons';
my %cmp = (
    'n == 2'   => 'T', 'n != 2'  => 'F',
    'n < 3'    => 'T', 'n > 3'   => 'F',
    'n <= 2'   => 'T', 'n >= 3'  => 'F',
    "w eq 'b'" => 'T', "w ne 'b'" => 'F',
    "w lt 'c'" => 'T', "w gt 'c'" => 'F',
    "w le 'b'" => 'T', "w ge 'c'" => 'F',
    'n == 2.0' => 'T', "s10 == 10" => 'T', "s10 eq '10.0'" => 'F',
);
for my $expr (sort keys %cmp) {
    is(r("{% if $expr %}T{% else %}F{% end %}",
         { n => 2, w => 'b', s10 => '10' }),
       $cmp{$expr}, $expr);
}

note 'boolean operators';
is(r('{% if a && b %}T{% else %}F{% end %}', { a => 1, b => 1 }), 'T',
   '&&');
is(r('{% if a and b %}T{% else %}F{% end %}', { a => 1, b => 0 }), 'F',
   'and');
is(r('{% if a || b %}T{% else %}F{% end %}', { b => 1 }), 'T', '||');
is(r('{% if a or b %}T{% else %}F{% end %}', {}), 'F', 'or');
is(r('{% if !a %}T{% end %}', {}), 'T', '!');
is(r('{% if not a == 1 %}T{% else %}F{% end %}', { a => 2 }), 'T',
   'not binds looser than comparison');
is(r('{% if a || b && c %}T{% else %}F{% end %}',
     { a => 0, b => 1, c => 0 }), 'F', '&& binds tighter than ||');
is(r('{% if (a || b) && c %}T{% else %}F{% end %}',
     { a => 1, c => 1 }), 'T', 'parentheses group');
is(r('{% if defined(v) %}D{% else %}U{% end %}', { v => 0 }), 'D',
   'defined()');
is(r("{% if v eq undef %}T{% else %}F{% end %}", { v => '' }), 'T',
   'undef literal in comparison');
is(r("{% if v eq 'it\\'s' %}T{% end %}", { v => "it's" }), 'T',
   'escaped quote in string literal');
is(r('{% if v == -1.5 %}T{% end %}', { v => -1.5 }), 'T',
   'negative decimal literal');

# ---- loops -----------------------------------------------------------

note 'loops';
is(r('{% for i in l %}{% i %};{% end %}', { l => [1, 2] }), '1;2;',
   'array loop');
is(r('{% for k, v in h %}{% k %}={% v %};{% end %}',
     { h => { b => 2, a => 1 } }), 'a=1;b=2;',
   'hash loop, sorted keys');
is(r('x{% for i in l %}!{% end %}y', { l => [] }), 'xy',
   'empty iterable renders nothing');
is(r('x{% for i in l %}!{% end %}y', {}), 'xy', 'missing iterable too');

note 'loop variable';
my $lt = '{% for i in l %}[{% loop.index %},{% loop.index1 %},'
       . '{% loop.size %},{% if loop.first %}F{% end %}'
       . '{% if loop.last %}L{% end %},'
       . '{% if loop.even %}E{% else %}O{% end %}]{% end %}';
is(r($lt, { l => [qw(a b c)] }), '[0,1,3,F,O][1,2,3,,E][2,3,3,L,O]',
   'index/index1/size/first/last/even/odd');
is(r('{% for k, v in h %}{% loop.key %}{% end %}', { h => { z => 1 } }),
   'z', 'loop.key in hash loops');
is(r('{% for o in l %}{% for i in o %}{% loop.index %}{% end %}|{% end %}',
     { l => [ [ 0, 0 ], [ 0 ] ] }), '01|0|', 'loop is the innermost');
is(r('{% for o in l %}{% set outer = loop %}{% for i in o %}'
   . '{% outer.index %}{% loop.index %} {% end %}{% end %}',
     { l => [ ['a'], ['b'] ] }), '00 10 ', 'capture with set');

# ---- set -------------------------------------------------------------

note 'set';
is(r("{% set x = 'lit' %}{% x %}", {}), 'lit', 'set string literal');
is(r('{% set x = 4.5 %}{% x %}', {}), '4.5', 'set number literal');
is(r('{% set x = a.b %}{% x %}', { a => { b => 'v' } }), 'v', 'set path');
is(r('{% set x = a || "fb" %}{% x %}', {}), 'fb', 'set expression');
is(r('{% set x = 1 %}{% set x = 2 %}{% x %}', {}), '2', 'rebind');
is(r('{% if 1 %}{% set x = "in" %}{% x %}{% end %}[{% x %}]',
     { x => 'out' }), 'in[out]', 'block scoped');
is(r('{% for i in l %}{% m %}{% set m = "!" %}{% end %}',
     { l => [ 1, 2 ] }), '', 'fresh each iteration');
is(r('{% set x = "s" %}{% x %}{% x %}', { x => 'data' }), 'ss',
   'set shadows data');

# ---- includes --------------------------------------------------------

note 'includes';
put('part.tmpl', 'P({% v %}/{% i %})');
is(r('{% for i in l %}{% include part.tmpl %}{% end %}',
     { l => [ 1 ], v => 'd' }), 'P(d/1)',
   'include shares scope and loop vars');
is(r('{% include part %}', { v => 'd' }), 'P(d/)',
   '.tmpl inference for includes');

# ---- wrapper ---------------------------------------------------------

note 'wrapper';
put('w.tmpl', '<w>{% content %}</w>');
is(r('body', {}, { wrapper => 'w.tmpl' }), '<w>body</w>',
   'wrapper via content');
{
    my $w = Template::Stencil->new(template_dir => $dir,
                                   wrapper => 'w.tmpl');
    is($w->render('b', {}), '<w>b</w>', 'engine-level wrapper');
    is($w->render('b', {}, { wrapper => undef }), 'b',
       'per-render disable');
}

# ---- comments and literal braces -------------------------------------

note 'comments and literals';
is(r('a{%# gone %}b', {}), 'ab', 'comment stripped');
is(r("a{%# multi\nline %}b", {}), 'ab', 'multi-line comment');
is(r('a{%%}b', {}), 'a{%b', '{%%} emits literal {%');
is(r('a %} b } c', {}), 'a %} b } c', 'bare closers are literal text');

# ---- render-time options --------------------------------------------

note 'options';
{
    my $strict = Template::Stencil->new(strict => 1);
    eval { $strict->render('{% gone %}', {}) };
    like($@, qr/undef value for 'gone'/, 'strict croaks on undef output');
    is($strict->render('{% if gone %}T{% else %}F{% end %}', {}), 'F',
       'strict allows undef in conditions');
}
{
    my $rawmode = Template::Stencil->new(auto_escape => 0);
    is($rawmode->render('{% v %}', { v => '<x>' }), '<x>',
       'auto_escape => 0');
}
{
    my $unsorted = Template::Stencil->new(sort_keys => 0);
    my $out = $unsorted->render('{% for k, v in h %}{% k %}{% end %}',
                                { h => { a => 1, b => 2 } });
    is(join('', sort split //, $out), 'ab', 'sort_keys => 0 still complete');
}
is(r('{% v %}', { v => "caf\x{e9}" }),
   do { my $b = "caf\x{e9}"; utf8::encode($b); $b },
   'output is UTF-8 bytes by default');
{
    my $chars = Template::Stencil->new(chars => 1);
    my $up = "caf\x{e9}"; utf8::upgrade($up);
    is($chars->render('{% v %}', { v => $up }), $up, 'chars => 1');
}

done_testing;
