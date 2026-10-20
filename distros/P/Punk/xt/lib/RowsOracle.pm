package RowsOracle;

# The in-memory model contract in plain Perl: the oracle the C in
# punk_mrows.h is compared against. Grown from lnation.org's
# LNATION::Backend::Rows, with the semantics the C documents: SQL's
# three-valued logic for NULL, numbers compared as numbers when both look
# like one, NULL sorting first, `like` with % and _.

use strict;
use warnings;
use Scalar::Util ();

sub cmpv {
    my ($a, $b) = @_;
    return defined $a <=> defined $b unless defined $a && defined $b;
    return $a <=> $b if Scalar::Util::looks_like_number($a)
                     && Scalar::Util::looks_like_number($b);
    return $a cmp $b;
}

sub like {
    my ($s, $p) = @_;
    my $re = join '', map { $_ eq '%' ? '.*' : $_ eq '_' ? '.' : quotemeta } split //, $p;
    return $s =~ /\A$re\z/s ? 1 : 0;
}

sub term {
    my ($op, $v, $want) = @_;
    my $d = defined $v;
    return !$d                         if $op eq '='  && !defined $want;
    return $d                          if $op eq '!=' && !defined $want;
    return $d && cmpv($v, $want) == 0  if $op eq '=';
    return $d && cmpv($v, $want) != 0  if $op eq '!=';
    return $d && cmpv($v, $want) < 0   if $op eq '<';
    return $d && cmpv($v, $want) <= 0  if $op eq '<=';
    return $d && cmpv($v, $want) > 0   if $op eq '>';
    return $d && cmpv($v, $want) >= 0  if $op eq '>=';
    if ($op eq 'in' || $op eq 'not_in') {
        return $op eq 'not_in' unless @$want;
        return 0 unless $d;
        my $found = grep { defined && cmpv($v, $_) == 0 } @$want;
        return $found ? 1 : 0 if $op eq 'in';
        return 0 if grep { !defined } @$want;
        return $found ? 0 : 1;
    }
    return $d && index($v, $want) == 0 if $op eq 'starts_with';
    return $d && like($v, $want)       if $op eq 'like';
    die "op $op";
}

sub matches {
    my ($filter, $row) = @_;
    for my $f (keys %$filter) {
        my $w = $filter->{$f};
        if (ref $w eq 'HASH') {
            for my $op (keys %$w) { return 0 unless term($op, $row->{$f}, $w->{$op}) }
        }
        else { return 0 unless term('=', $row->{$f}, $w) }
    }
    return 1;
}

# order: [ [col, desc], ... ] with the pk appended as the C does
sub search {
    my ($rows, $pk, $filter, $order, $limit) = @_;
    my @spec = @$order;
    push @spec, [ $pk, @spec ? $spec[-1][1] : 0 ] unless grep { $_->[0] eq $pk } @spec;
    my @r = sort {
        my $c = 0;
        for my $s (@spec) { last if $c = cmpv($a->{ $s->[0] }, $b->{ $s->[0] }) * ($s->[1] ? -1 : 1) }
        $c;
    } grep { matches($filter, $_) } @$rows;
    return [ map $_->{$pk}, @r ];
}

1;
