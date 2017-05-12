use Test::More tests => 63;
BEGIN { use_ok('Sub::Curry') };

#########################

### Test spices

use strict;
use Sub::Curry qw/ :CONST curry /;

my %spice = (
    _   => HOLE,
    _ah => ANTIHOLE,
    _bh => BLACKHOLE,
    _wh => WHITEHOLE,
    _as => ANTISPICE,
);

my %alias = reverse %spice;

sub result { join ' ', map { defined() ? $alias{$_} ? $alias{$_} : $_ : '*' } @_ }

sub test {
    my ($test) = @_;

    (my ($args, $result) = split /=>/, $test)
        >= 2 or die "Internal error: no result for '$_'";
    my ($create, @clones) = split /->/, $args;
    my $call = pop @clones;

    $result = [ split ' ', $result ];
    for ($create, @clones, $call) {
        $_ = [ map { $spice{$_} ? $spice{$_} : $_ } split ];
    }

    for ($create, @clones, $call, $result) {
        for (@$_) {
            die "Don't use _ except for spices"
                if /^_/ and not $spice{$_};
        }
    }

    #print Dumper [ $create, \@clones, $call, $result ];

    my $o = curry(\&result, @$create);
    for (@clones) {
        $o = $o->new(@$_);
    }

    my $r1 = $o->(@$call);
    my $r2 = result(@$result);
    my $txt = $test;
    if ($r1 ne $r2) {
        $txt .= " | returned '$r1' | " . $o->_code_str;
    }
    ok($r1 eq $r2, $txt);
}

#     A B -> C -> D -> E => F
# is translated to a subroutine call and a comparision.
#     Sub::Curry::->new(\&foo, A, B)->new(C)->new(D)->(E) eq F
# Multiple arguments are separated by whitespace.
# See %spice for a translation of the special tokens found in
# the tests between ->.

my @tests = grep !/^\s*\#/ && !/^\s*$/ => split /\n+/, <<'_TESTS_';
    # no spice
    -> =>
    a -> => a
    -> a => a
    a -> b => a b
    a b -> c d => a b c d

    # hole
    _ -> => *
    _ a -> => * a
    _ -> a => a
    _ a -> b => b a

    # antispice
    _as -> =>
    _as -> a =>
    _as a -> b => a
    a _as b -> c => a b

    # blackhole
    _bh -> =>
    _bh -> a => a
    _bh -> a b => a b
    a _bh -> b c => a b c
    _bh a -> b c => b c a
    _bh _ -> a b => a b *

    # chain
    -> -> =>
    a -> -> => a
    -> a -> => a
    -> -> a => a
    a -> b -> => a b
    a -> -> b => a b
    -> a -> b => a b
    a -> b -> c => a b c

    # antihole
    _ a -> _ah b -> => a b
    _ _ a -> _ah b -> => b a

    # whitehole
    a _bh b -> _wh c d -> => a b c d
    a _ b -> _wh c d -> => a _wh b c d
    a _as b -> _wh c d -> => a b c d
_TESTS_

for (@tests) {
    s/^\s+//;
    tr/ //s;
}

push @tests => map {
    my $new = reverse;
    $new =~ s/>=(?!\s*>-\s*>-)/>= >-/
        ? scalar reverse $new
        : ();
} @tests;

test($_) for @tests;
