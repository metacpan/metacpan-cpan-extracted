#!/usr/bin/env perl
# Provenance: no R or SciPy counterpart (group_by() is this module's own).
# Pins the 0.3419 fix: group_by() opened an ENTER/LEAVE for each row but no
# tmps scope, so the mortal key SV that hv_iterkeysv() returns for every filter
# of every row lived until the XSUB returned (500000 rows x 1 filter grew the
# process by 8MB).  A tied filter hash whose key is an object makes the
# lifetime observable: the key's mortal holds the only reference, so its
# DESTROY runs when the mortal is freed.  With the fix it runs before the next
# row; before it, after the last.
require 5.010;
use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(group_by);

our $destroyed = 0;
{ package Key; use overload '""' => sub { 'w' }, fallback => 1;
  sub new { bless {}, shift } sub DESTROY { $::destroyed++ } }
{ package TiedFilter;
  sub TIEHASH { bless {}, shift }
  sub FIRSTKEY { Key->new }
  sub NEXTKEY { undef }
  sub FETCH { my $self = shift; sub { 1 } }
  sub EXISTS { 1 }
}

my $n = 20;
my @seen;
tie my %filter, 'TiedFilter';
# the filter sub is the FETCH result, so record the counter from a wrapper
{
	no warnings 'redefine';
	*TiedFilter::FETCH = sub { push @seen, $destroyed; sub { 1 } };
}
my @rows = map { { v => $_, g => 'a', w => $_ } } 1 .. $n;
my $r = group_by(\@rows, 'v', 'g', \%filter);
is_deeply($r, { a => [1 .. $n] }, 'result unchanged');
is(scalar(@seen), $n, 'the filter was consulted for every row');
cmp_ok($seen[-1], '>=', $n - 2, 'keys of earlier rows were already freed when the last row ran');

my %hoa = (v => [1 .. $n], g => [('a') x $n], w => [1 .. $n]);
@seen = (); $destroyed = 0;
$r = group_by(\%hoa, 'v', 'g', \%filter);
is_deeply($r, { a => [1 .. $n] }, 'HoA result unchanged');
cmp_ok($seen[-1], '>=', $n - 2, 'HoA: earlier rows freed');

my %hoh = map { ("r$_" => { v => $_, g => 'a', w => $_ }) } 1 .. $n;
@seen = (); $destroyed = 0;
$r = group_by(\%hoh, 'v', 'g', \%filter);
is(scalar(@{ $r->{a} }), $n, 'HoH result size unchanged');
cmp_ok($seen[-1], '>=', $n - 2, 'HoH: earlier rows freed');

done_testing;
