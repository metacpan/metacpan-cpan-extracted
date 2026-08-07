#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub checker { Template::Stencil::_stencil_stats()->{checker} }

my $s = Template::Stencil->new;
my $data = { v => '<hi>' };

# Statically resolved calls go through the checker-installed custom pp
# (observable via the counter); method calls use the plain XSUB. Both
# must produce identical results.
# cv_set_call_checker needs perl 5.14; below that every call goes through
# the ordinary XSUB, so the counter never moves. Results must be identical
# either way - that is the part worth asserting on every perl.
my $has_checker = $] >= 5.014;

my $c0 = checker();
my $via_fn = Template::Stencil::render($s, '{% v %}', $data);
my $c1 = checker();
SKIP: {
    skip 'call checker needs perl 5.14+', 2 unless $has_checker;
    cmp_ok($c1, '>', $c0, 'function-style call took the fast path');

    my $via_method_c = $s->render('{% v %}', $data);
    my $c2 = checker();
    is($c2, $c1, 'method call does not take the checker path');
}

my $via_method = $s->render('{% v %}', $data);
is($via_fn, $via_method, 'both paths byte-identical');
is($via_fn, '&lt;hi&gt;', 'and correct');

# All arities through the fast path.
is(Template::Stencil::render($s, 'plain'), 'plain', '2-arg fast path');
is(Template::Stencil::render($s, '{% v %}', { v => 1 }), '1',
   '3-arg fast path');
is(Template::Stencil::render($s, '{% m %}', {}, { strict => 0 }), '',
   '4-arg fast path');

# Errors still croak cleanly through the fast path.
eval { Template::Stencil::render($s, '{% if x %}', {}) };
like($@, qr/unclosed 'if'/, 'compile error via fast path');
eval { Template::Stencil::render('nope', 'x', {}) };
like($@, qr/not a Template::Stencil object/,
     'invocant guard via fast path');
eval { Template::Stencil::render($s) };
like($@, qr/Usage:/, 'arity guard');

# Amp-call is also statically resolvable and must behave identically.
is(&Template::Stencil::render($s, '{% v %}', $data), '&lt;hi&gt;',
   'amp call correct');

done_testing;
