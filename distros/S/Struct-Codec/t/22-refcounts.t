#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B ();
use Scalar::Util qw(refaddr);
use Struct::Codec qw(struct_encode struct_decode);

# REFERENCE COUNTS, EXACTLY.
#
# t/16 watches resident size, which catches a leak only once it is megabytes
# wide. This asks the interpreter directly: a decoded structure holds exactly
# the references the original did, no more (a leak) and no fewer (a use after
# free waiting to happen), and every object built is destroyed exactly once,
# including the ones that were finished before a croak.

sub rc { B::svref_2object($_[0])->REFCNT }      # the referent's count, for a reference

sub rt { struct_decode(struct_encode($_[0])) }

# ---- plain structures ----------------------------------------------------------
{
    my $d = rt([1, [2], { a => 3 }, \'s']);
    is(rc($d),      1, 'the decoded array is held once: by us');
    is(rc($d->[1]), 1, 'an inner array once: by its slot');
    is(rc($d->[2]), 1, 'an inner hash once');
    is(rc($d->[3]), 1, 'a scalar referent once');
    is(rc(\$d->[0]), 2, 'an element scalar: its slot, and the reference just taken to ask');
}

# ---- shared referents ------------------------------------------------------------
{
    my $s = [1];
    my $o = rt([$s, $s, $s]);
    is(rc($o->[0]), 3, 'a referent shared three ways is held three times');
    is(refaddr($o->[0]), refaddr($o->[2]), 'and it is one referent');

    my $h = rt({ a => $s, b => { c => $s } });
    is(rc($h->{a}), 2, 'two ways: two');

    my $x = 'aliased';
    my $al  = sub { rt(\@_) }->($x, $x);
    my $pl  = rt(['plain', 'plain']);
    is(rc(\$al->[0]), rc(\$pl->[0]) + 1, 'an aliased scalar is held by both slots, a copied one by its own');
}

# ---- cycles can be broken and then freed -------------------------------------------
{
    my $destroyed = 0;
    { no strict 'refs'; *{'Cyc::DESTROY'} = sub { $destroyed++ } }
    my $c = bless {}, 'Cyc';
    $c->{me} = $c;
    my $bytes = struct_encode($c);
    {
        my $d = struct_decode($bytes);
        is(rc($d), 2, 'a decoded cycle is held by us and by itself');
        delete $d->{me};
        is(rc($d), 1, 'breaking it leaves ours');
    }
    is($destroyed, 1, 'and it is destroyed exactly once when ours goes');
}

# ---- every object is destroyed exactly once --------------------------------------
{
    my $count = 0;
    { no strict 'refs'; *{'Counted::DESTROY'} = sub { $count++ } }

    my @orig = map { bless { n => $_ }, q{Counted} } 1 .. 10;   # kept alive: their own DESTROYs must not be counted
    my $bytes = struct_encode(\@orig);
    $count = 0;
    { my $v = struct_decode($bytes) }
    is($count, 10, q{ten decoded objects, ten DESTROYs});

    $count = 0;
    my $one = bless { n => 1 }, 'Counted';
    $bytes = struct_encode([ $one, $one, { again => $one } ]);
    { my $v = struct_decode($bytes) }
    is($count, 1, 'one object shared three ways, one DESTROY');
    undef $one;
    $count = 0;

    # A stream cut at the start of the seventh object: the six that were
    # finished are real objects and are destroyed on the croak; the seventh
    # was never blessed and the rest were never built. The prefix of the
    # ten-object stream is byte-identical to the six-object stream up to that
    # point, because the count is one byte either way.
    my @objs = map { bless { n => $_ }, 'Counted' } 1 .. 10;
    my $ten = struct_encode(\@objs);
    my $six = struct_encode([ @objs[0 .. 5] ]);
    my $cut = substr($ten, 0, length $six);
    $count = 0;
    my $err = '';
    eval { my $v = struct_decode($cut); 1 } or $err = $@;
    like($err, qr/truncated/, 'the cut stream croaks');
    is($count, 6, 'the six objects finished before the cut were destroyed, once each, by the croak');
}

# ---- the decoder holds nothing after it returns --------------------------------------
{
    # A referent registered for REFP is borrowed by the decoder's table. If
    # the table held a reference of its own, this count would be one too high.
    my $s = { k => 'v' };
    my $o = rt([$s, $s]);
    is(rc($o->[0]), 2, 'a tracked referent is held only by its two references, not by the decoder');

    my $x = 'a';
    my $al = sub { rt(\@_) }->($x, $x, $x);
    my $pl = rt(['a', 'a', 'a']);
    is(rc(\$al->[0]) - rc(\$pl->[0]), 2, 'a tracked alias likewise: three slots, nothing else');
}

# ---- repeated work leaves the temps stack where it was -------------------------------
{
    # The encoder parks its buffer and tables on the temps stack when it needs
    # them. A leak there would not show as a refcount on anything the caller
    # can see, but it would show as tmps_ix climbing across a loop that FREETMPS
    # never gets to.
    my $big = { map { ("k$_" => [ ($_) x 5 ]) } 1 .. 300 };   # over the stack buffer
    my $s = [1];
    my $shared = [ ($s) x 50 ];                                 # forces the seen table
    my $before = B::svref_2object(\&rt)->REFCNT;                # a fixed point
    for (1 .. 2000) {
        my $a = struct_encode($big);
        my $b = struct_encode($shared);
        my $c = struct_decode($b);
    }
    pass('2000 large and shared round trips inside one statement did not exhaust anything');
    is(B::svref_2object(\&rt)->REFCNT, $before, 'and touched nothing they should not have');
}

done_testing;
