#!/usr/bin/env perl

# Tests for group_by()'s filter argument on Hash-of-Hashes (HoH) input.
# This path is exercised by t/01.t only for Array-of-Hashes and
# Hash-of-Arrays input, so the HoH + filter combination is covered here.

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

#--------
# A single filter column: keep only the rows where Sex eq 'f'.
# The group ('Gender') and target ('Testosterone') columns are independent
# of the filter column ('Sex'), so this checks that the filter selects rows
# by a third column while grouping/collecting by the other two.
#--------
my $hoh = {
	Patient_A => { Gender => 'Male',   Sex => 'm', Testosterone => 20.5 },
	Patient_B => { Gender => 'Female', Sex => 'f', Testosterone => 1.8  },
	Patient_C => { Gender => 'Male',   Sex => 'f', Testosterone => 18.2 },
	Patient_D => { Gender => 'Female', Sex => 'f', Testosterone => 2.1  },
	Patient_E => { Gender => 'Male',   Sex => 'm', Testosterone => 15.0 },
};

my $res = group_by($hoh, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });

is(ref $res,           'HASH', 'HoH filter: returns a hashref');
is(scalar keys %$res,  2,      'HoH filter: two group keys survive');

# Sort defensively: HoH iteration order is randomized.
my @male   = sort { $a <=> $b } @{ $res->{Male}   || [] };
my @female = sort { $a <=> $b } @{ $res->{Female} || [] };

is(scalar @male,   1, 'HoH filter: Male keeps only the one Sex=f row');
is($male[0],       18.2, 'HoH filter: Male value is the female-flagged 18.2');
is(scalar @female, 2, 'HoH filter: Female keeps both Sex=f rows');
is_deeply(\@female, [ 1.8, 2.1 ], 'HoH filter: Female values collected correctly');

#--------
# Two filter columns behave as a logical AND: a row must satisfy every sub.
# Here Sex eq 'f' AND Testosterone > 2 drops the female-flagged 1.8. The two
# subs may be packed into ONE hashref...
#--------
my $res2 = group_by(
	$hoh, 'Testosterone', 'Gender',
	{ Sex => sub { $_ eq 'f' }, Testosterone => sub { $_ > 2 } },
);

is(scalar keys %$res2, 2, 'HoH multi-filter (1 hashref): two group keys survive');
is_deeply($res2->{Male},   [ 18.2 ], 'HoH multi-filter (1 hashref): Male unchanged');
is_deeply($res2->{Female}, [ 2.1  ], 'HoH multi-filter (1 hashref): 1.8 excluded by T > 2');

#--------
# ...or spread across SEPARATE hashref arguments, as the README documents.
# Every filter hashref from the 4th argument onward is applied (ANDed), so
# this must give an identical result to the single-hashref form above.
#--------
my $res2b = group_by(
	$hoh, 'Testosterone', 'Gender',
	{ Sex => sub { $_ eq 'f' } },
	{ Testosterone => sub { $_ > 2 } },
);

is(scalar keys %$res2b, 2, 'HoH multi-filter (2 hashrefs): two group keys survive');
is_deeply($res2b->{Male},   [ 18.2 ], 'HoH multi-filter (2 hashrefs): Male unchanged');
is_deeply($res2b->{Female}, [ 2.1  ], 'HoH multi-filter (2 hashrefs): 2nd filter is applied, 1.8 excluded');

#--------
# A filter that matches nothing yields no groups at all (an empty hash),
# because a group key is only created when at least one row passes.
#--------
my $res3 = group_by($hoh, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'nope' } });
is(scalar keys %$res3, 0, 'HoH filter: matching nothing returns an empty hash');

#--------
# Rows missing the target, or whose target is explicitly undef, are dropped
# even when they pass the filter (the target guard runs regardless of filter).
#--------
my $hoh2 = {
	R1 => { G => 'X', Keep => 'y', V => 10       }, # kept
	R2 => { G => 'X', Keep => 'y'                }, # target missing -> dropped
	R3 => { G => 'X', Keep => 'y', V => undef    }, # target undef   -> dropped
	R4 => { G => 'Y', Keep => 'n', V => 5        }, # filtered out
};
my $res4 = group_by($hoh2, 'V', 'G', { Keep => sub { $_ eq 'y' } });

is(scalar keys %$res4, 1,      'HoH filter: only the group with a kept row exists');
is_deeply($res4->{X},  [ 10 ], 'HoH filter: missing/undef targets excluded despite passing filter');
ok(!exists $res4->{Y}, 'HoH filter: fully filtered-out group is absent');

#--------
# A filter that names a column absent from every row is fatal, rather than
# silently treating the missing column as undef. (A column present but never
# matching -- as tested above -- still just yields an empty result.)
#--------
my $died = !eval {
	group_by($hoh, 'Testosterone', 'Gender', { Ghost => sub { $_ eq 'x' } });
	1;
};
ok($died, 'HoH filter: dies when a filter names an absent column');
like($@, qr/group_by: "Ghost" is not present in the dataset/,
	'HoH filter: absent-column death carries the expected message');

#--------
# No memory leaks on the HoH + filter path (including the empty-result case).
#--------
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok {
	group_by($hoh,  'Testosterone', 'Gender', { Sex  => sub { $_ eq 'f'    } });
	group_by($hoh,  'Testosterone', 'Gender', { Sex  => sub { $_ eq 'nope' } });
	group_by($hoh2, 'V',            'G',      { Keep => sub { $_ eq 'y'    } });
} 'group_by: no leaks with Hash-of-Hashes input and a filter';

done_testing();
