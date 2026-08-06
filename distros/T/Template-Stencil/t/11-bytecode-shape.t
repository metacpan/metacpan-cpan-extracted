#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Template::Stencil;

sub inspect { Template::Stencil::_inspect($_[0]) }

# SHORT for <= 31 bytes, LONG above.
{
    my $o31 = inspect('x' x 31)->{ops};
    is($o31->[0]{op}, 'SOP_LITERAL_SHORT', '31 bytes stays SHORT');
    my $o32 = inspect('x' x 32)->{ops};
    is($o32->[0]{op}, 'SOP_LITERAL_LONG', '32 bytes goes LONG');
    is($o32->[0]{len}, 32, 'LONG length');
}

# Const-fold: a template with no tags is one literal + END, even large.
{
    my $i = inspect("no tags here\n" x 500);
    is(scalar @{ $i->{ops} }, 2, 'const-fold to one literal op');
    is($i->{ops}[0]{op}, 'SOP_LITERAL_LONG', 'folded op is LONG');
}

# Adjacent merge across a comment boundary.
{
    my $long = 'y' x 20;
    my $i = inspect($long . '{%# gone %}' . $long);
    is(scalar @{ $i->{ops} }, 2, 'comment-split literals merge');
    is($i->{ops}[0]{len}, 40, 'merged length');
}

# Literal pool dedup: identical LONG literals share one pool offset.
{
    my $chunk = 'z' x 64;
    my $i = inspect($chunk . '{% v %}' . $chunk);
    my @longs = grep { $_->{op} eq 'SOP_LITERAL_LONG' } @{ $i->{ops} };
    is(scalar @longs, 2, 'two LONG literals');
    is($longs[0]{off}, $longs[1]{off}, 'deduped to one pool offset');
}

# Static stack high-water.
{
    is(inspect('{% v %}')->{max_stack}, 1, 'plain output max_stack 1');
    is(inspect('{% if a == b %}x{% end %}')->{max_stack}, 2,
       'comparison max_stack 2');
    is(inspect('{% if a %}x{% end %}')->{max_stack}, 1,
       'truthy test max_stack 1');
}

# Frames / binds high-water.
{
    my $i = inspect('{% for a in x %}{% for b in a %}{% set c = b %}{% end %}{% end %}');
    is($i->{max_frames}, 2, 'nested for frames');
    is($i->{max_binds}, 1, 'set binds');
}

# is_wrapper flag.
is(inspect('{% content %}')->{is_wrapper}, 1, 'content flags wrapper');
is(inspect('{% x %}')->{is_wrapper}, 0, 'no content, no wrapper');

# Golden op sequence for the draft-test fixture.
{
    open my $fh, '<', 't/template/loops.tmpl' or die $!;
    my $src = do { local $/; <$fh> };
    my $got = join "\n", map $_->{op}, @{ inspect($src)->{ops} };
    open my $gf, '<', 't/corpus/loops.ops' or die $!;
    my $want = do { local $/; <$gf> };
    chomp $want;
    is($got, $want, 'loops.tmpl golden op sequence');
}

# Cold-compile budget (informational diag; generous assert only to
# catch catastrophic regressions).
{
    my $tmpl = ('<li>' . ('x' x 20) . '{% item.name %}</li>') x 20;
    $tmpl .= '{% if a %}{% for i in items %}{% i %}{% end %}{% end %}';
    my $n  = 2000;
    my $t0 = Time::HiRes::time();
    inspect($tmpl) for 1 .. $n;   # includes inspect overhead
    my $us = (Time::HiRes::time() - $t0) / $n * 1e6;
    diag(sprintf 'cold compile+inspect of %d-byte template: %.1f us',
         length $tmpl, $us);
    cmp_ok($us, '<', 1000, 'compile time within catastrophic bound');
}

done_testing;
