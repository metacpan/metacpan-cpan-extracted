#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr reftype blessed);
use Storable qw(freeze thaw);
use Struct::Codec qw(struct_encode struct_decode);

# STRUCTURES NOBODY WROTE BY HAND.
#
# A seeded generator builds a few hundred random structures - every scalar
# kind, containers to depth five, blessed referents, and a pool of referents
# that are reused so sharing appears in random places - and each one must:
#
#   * come back equal, by is_deeply;
#   * come back with the SAME sharing, measured as the set of (path, referent)
#     identities, not merely equal contents;
#   * agree with Storable's view of it;
#   * survive a SECOND round trip with the same contents and sharing. (Not
#     byte-identical: perl perturbs hash iteration order per hash, so two
#     equal hashes encode their keys in different orders, by design.)
#   * die at every truncation.
#
# SC_SEED in the environment picks the seed, and a failure prints it.

my $seed = defined $ENV{SC_SEED} ? $ENV{SC_SEED} : 20260911;
srand($seed);
diag("seed $seed") if $ENV{SC_SEED};

my @pool;                       # shared referents for this structure
my @classes = ('Rnd::A', 'Rnd::B', "Rnd::\x{263a}");

sub rstr {
    my $n = int rand 40;
    my $wide = rand() < 0.3;
    return join '', map { chr($wide ? int rand 0x3000 : int rand 256) } 1 .. $n;
}

sub scalar_ {
    my $r = rand;
    return undef                         if $r < 0.08;
    return int(rand(2**20)) - 2**19      if $r < 0.30;
    return rand() * 1e6 - 5e5            if $r < 0.42;
    return rstr()                        if $r < 0.85;
    return '' . int rand 1000            if $r < 0.92;    # a numeric-looking string
    return 2**40 + int rand 1000         if $r < 0.96;
    return 0.5 ** (int rand 60);
}

sub gen {
    my ($depth) = @_;
    my $r = rand;
    return scalar_() if $depth >= 5 || $r < 0.35;
    if (@pool && $r < 0.45) { return $pool[int rand @pool] }   # share something
    my $v;
    if ($r < 0.70) {
        $v = [ map { gen($depth + 1) } 1 .. int rand 6 ];
    }
    elsif ($r < 0.93) {
        $v = { map { (rstr() => gen($depth + 1)) } 1 .. int rand 6 };
    }
    else {
        my $s = scalar_();
        $v = \$s;
    }
    bless $v, $classes[int rand @classes] if rand() < 0.15;
    push @pool, $v if rand() < 0.5;
    return $v;
}

# The sharing signature: for every reference reachable, the path to it and a
# small integer naming its referent (first-seen order). Two structures with
# the same signature share in exactly the same places.
sub signature {
    my ($v, $path, $ids, $out) = @_;
    return unless ref $v;
    my $a = refaddr($v);
    $ids->{$a} = scalar keys %$ids unless exists $ids->{$a};
    push @$out, "$path=$ids->{$a}";
    return if $out->[-1] =~ /\*$/;        # already walked (cannot happen without cycles)
    if (reftype($v) eq 'ARRAY')  { signature($v->[$_], "$path/$_", $ids, $out) for 0 .. $#$v }
    elsif (reftype($v) eq 'HASH') { signature($v->{$_}, "$path/{$_}", $ids, $out) for sort keys %$v }
    elsif (reftype($v) eq 'SCALAR' || reftype($v) eq 'REF') { signature($$v, "$path/\$", $ids, $out) }
}

sub sig { my @o; signature($_[0], '', {}, \@o); return join "\n", @o }

my $N = $ENV{SC_ROUNDS} || 300;
my ($ok_deep, $ok_share, $ok_storable, $ok_stable, $ok_trunc, $tried_trunc) = (0) x 6;
my @failed;

for my $i (1 .. $N) {
    @pool = ();
    my $v = gen(0);
    $v = [$v] unless ref $v;              # Storable wants a reference
    my $b = struct_encode($v);
    my $d = struct_decode($b);

    if (is_deeply_quiet($d, $v)) { $ok_deep++ } else { push @failed, "$i: contents" }
    if (sig($d) eq sig($v))       { $ok_share++ } else { push @failed, "$i: sharing" }
    if (is_deeply_quiet($d, thaw(freeze($v)))) { $ok_storable++ } else { push @failed, "$i: storable" }
    { my $dd = struct_decode(struct_encode($d));
      if (is_deeply_quiet($dd, $v) && sig($dd) eq sig($v)) { $ok_stable++ } else { push @failed, "$i: second trip" } }

    # a handful of truncations per structure keeps the file fast
    for my $cut (map { int rand length $b } 1 .. 5) {
        $tried_trunc++;
        $ok_trunc++ unless eval { my $x = struct_decode(substr($b, 0, $cut)); 1 };
    }
}

is($ok_deep,     $N, "$N random structures came back equal");
is($ok_share,    $N, 'and shared in exactly the same places');
is($ok_storable, $N, 'and agree with Storable');
is($ok_stable,   $N, q{and survive a second round trip with the same contents and sharing});
is($ok_trunc, $tried_trunc, "and every one of $tried_trunc random truncations died");
diag("seed $seed, failures: @failed") if @failed;

# is_deeply without the TAP line, so a 300-structure loop is five tests and
# not fifteen hundred; the first failure is reported with the seed.
sub is_deeply_quiet {
    my ($got, $want) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tb = Test::More->builder;
    my $ok;
    {
        # Test::More has no quiet is_deeply; compare through its own engine.
        no warnings 'redefine';
        local *Test::Builder::ok = sub { $ok = $_[1]; $_[1] };
        local *Test::Builder::diag = sub { 1 };
        Test::More::is_deeply($got, $want, '');
    }
    return $ok;
}

done_testing;
