package PORef;
# A brute-force reference executor, in Perl.
#
# DELIBERATELY SLOW AND OBVIOUSLY CORRECT. It filters with grep and sorts with
# sort; there is no index, no pushdown, no early stop and no cleverness of any
# kind. Its whole job is to be a second opinion the C executor is checked
# against over generated corpora.
#
# It shares no code with the C, and it implements only what the tests ask of
# it - which is the honest scope for a reference: enough to disagree.
use strict;
use warnings;

# A tiny query reader. It handles the subset the comparison tests use, and
# refuses anything else loudly rather than silently doing something else.
sub run {
    my ($query, $rows) = @_;
    my @r = @$rows;

    my ($src, @stages) = split /\s*\|\s*/, $query;
    $src =~ s/^\s+|\s+$//g;

    my $kind = $src =~ /^metric/  ? 'metric'
             : $src =~ /^log/     ? 'log'
             : $src =~ /^trace/   ? 'span'
             : $src =~ /^span/    ? 'span'
             : die "PORef: unknown source '$src'";

    my ($agg, @by, $limit);

    for my $st (@stages) {
        $st =~ s/^\s+|\s+$//g;
        if ($st =~ /^where\s+(.*)$/) {
            my $pred = _pred($1);
            @r = grep { $pred->($_) } @r;
        }
        elsif ($st =~ /^search\s+"(.*)"$/) {
            my $needle = lc $1;
            @r = grep { defined $_->{body} && index(lc $_->{body}, $needle) >= 0 } @r;
        }
        elsif ($st =~ /^(count|sum|avg|min|max|p50|p90|p95|p99)(?:\s+by\s+(.*))?$/) {
            $agg = $1;
            @by  = $2 ? (map { (my $v = $_) =~ s/^\s+|\s+$//g; $v } split /\s*,\s*/, $2) : ();
        }
        elsif ($st =~ /^limit\s+(\d+)$/) { $limit = $1 }
        elsif ($st =~ /^slowest\s+(\d+)$/) {
            @r = sort { ($b->{duration} // 0) <=> ($a->{duration} // 0) } @r;
            $limit = $1;
        }
        else { die "PORef: unsupported stage '$st'" }
    }

    if ($agg) {
        my %g;
        for my $row (@r) {
            my $key = join "\x1f", map { _field($row, $_) // '' } @by;
            push @{ $g{$key} }, $row;
        }
        my @out;
        for my $key (sort keys %g) {
            my @rows = @{ $g{$key} };
            my $val;
            if ($agg eq 'count') { $val = scalar @rows }
            else {
                my $f = $kind eq 'span' ? 'duration'
                      : $kind eq 'log'  ? 'severity' : 'value';
                my @v = map { $_->{$f} // 0 } @rows;
                if    ($agg eq 'sum') { $val = 0; $val += $_ for @v }
                elsif ($agg eq 'avg') { $val = 0; $val += $_ for @v;
                                        $val = @v ? $val / @v : 0 }
                elsif ($agg eq 'min') { $val = (sort { $a <=> $b } @v)[0] }
                elsif ($agg eq 'max') { $val = (sort { $a <=> $b } @v)[-1] }
                else {
                    my ($q) = $agg =~ /^p(\d+)$/;
                    my @s = sort { $a <=> $b } @v;
                    my $idx = ($q / 100) * (scalar(@s) - 1);
                    my $lo = int $idx;
                    my $hi = $lo + 1 < @s ? $lo + 1 : $lo;
                    $val = $s[$lo] + ($s[$hi] - $s[$lo]) * ($idx - $lo);
                }
            }
            push @out, { key => $key, value => $val, count => scalar @rows };
        }
        return { shape => (@by ? 'series' : 'scalar'), groups => \@out };
    }

    @r = @r[0 .. $limit - 1] if defined $limit && $limit < @r;
    return { shape => 'rows', rows => \@r };
}

sub _field {
    my ($row, $f) = @_;
    return $row->{$f} if exists $row->{$f};
    return $row->{attrs}{$f} if $row->{attrs} && exists $row->{attrs}{$f};
    return undef;
}

# One comparison, or a conjunction of them. No or, no not, no parentheses -
# the C is tested for those separately by its own AST dump.
sub _pred {
    my ($src) = @_;
    my @parts = split /\s+and\s+/, $src;
    my @tests;
    for my $p (@parts) {
        $p =~ s/^\s+|\s+$//g;
        my ($f, $op, $v) = $p =~ /^(\S+)\s*(=~|!~|!=|<=|>=|=|<|>)\s*(.+)$/
            or die "PORef: cannot parse predicate '$p'";
        $v =~ s/^\s+|\s+$//g;
        my $str = $v =~ s/^"(.*)"$/$1/ ? 1 : 0;
        # Severity NAMES are numeric on the 24-point scale. Without this the
        # reference compared "error" numerically against 0 and passed every
        # row - a broken reference that made a correct executor look wrong.
        my %SEV = (trace=>1, debug=>5, info=>9, warn=>13, warning=>13,
                   error=>17, fatal=>21);
        if (!$str && exists $SEV{lc $v}) { $v = $SEV{lc $v} }
        my $num = !$str;
        if ($num && $v =~ /^(\d+(?:\.\d+)?)(ns|us|ms|s|m|h|d|w)$/) {
            my %u = (ns=>1, us=>1e3, ms=>1e6, s=>1e9, m=>6e10,
                     h=>3.6e12, d=>8.64e13, w=>6.048e14);
            $v = $1 * $u{$2};
        }
        push @tests, sub {
            my ($row) = @_;
            my $got = _field($row, $f);
            return 0 unless defined $got;
            if ($str) {
                return index($got, $v) >= 0 if $op eq '=~';
                return index($got, $v) <  0 if $op eq '!~';
                return $op eq '='  ? $got eq $v
                     : $op eq '!=' ? $got ne $v
                     : $op eq '<'  ? ($got lt $v)
                     : $op eq '>'  ? ($got gt $v)
                     : $op eq '<=' ? ($got le $v)
                     :               ($got ge $v);
            }
            return $op eq '='  ? $got == $v
                 : $op eq '!=' ? $got != $v
                 : $op eq '<'  ? $got <  $v
                 : $op eq '>'  ? $got >  $v
                 : $op eq '<=' ? $got <= $v
                 :               $got >= $v;
        };
    }
    return sub { my $r = shift; for my $t (@tests) { return 0 unless $t->($r) } 1 };
}

1;
