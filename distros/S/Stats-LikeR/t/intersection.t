#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

# --- basic intersection --------------------------------------------------
my @basic = intersection([1, 2, 3], [2, 3, 4]);
no_leaks_ok {
	eval { intersection([1, 2, 3], [2, 3, 4]) }
} 'intersection: basic no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@basic, [2, 3], 'intersection keeps values present in every ref';

# --- three refs ----------------------------------------------------------
my @three = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4, 5]);
no_leaks_ok {
	eval { intersection([1, 2, 3, 4], [2, 3, 4], [3, 4, 5]) }
} 'intersection: three refs no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@three, [3, 4], 'intersection across three refs';

# --- duplicates within a ref are counted once ---------------------------
my @dup = intersection([1, 2, 2, 3], [2, 3, 3, 4]);
no_leaks_ok {
	eval { intersection([1, 2, 2, 3], [2, 3, 3, 4]) }
} 'intersection: within-ref dup no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@dup, [2, 3], 'intersection ignores duplicates inside a single ref';

# --- result order follows the first ref ----------------------------------
my @ord = intersection([3, 1, 2], [1, 2, 3]);
no_leaks_ok {
	eval { intersection([3, 1, 2], [1, 2, 3]) }
} 'intersection: order no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@ord, [3, 1, 2], 'intersection returns first-ref order, deduplicated';

# --- string equality semantics ("3" ne "3.0") ---------------------------
my @eq = intersection([1, 2, 3], ["2", "3.0", "9"]);
no_leaks_ok {
	eval { intersection([1, 2, 3], ["2", "3.0", "9"]) }
} 'intersection: string-eq no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@eq, [2], 'intersection compares by stringification: "2" matches, "3.0" does not';

# --- single ref reduces to its unique values -----------------------------
my @one = intersection([1, 2, 2, 3]);
no_leaks_ok {
	eval { intersection([1, 2, 2, 3]) }
} 'intersection: single ref no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@one, [1, 2, 3], 'intersection of one ref is its unique values';

# --- an empty ref forces an empty result ---------------------------------
my @emp = intersection([1, 2], []);
no_leaks_ok {
	eval { intersection([1, 2], []) }
} 'intersection: empty ref no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@emp, [], 'intersection with an empty ref is empty';

# --- disjoint sets -------------------------------------------------------
my @dis = intersection([1, 2], [3, 4]);
no_leaks_ok {
	eval { intersection([1, 2], [3, 4]) }
} 'intersection: disjoint no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@dis, [], 'intersection of disjoint sets is empty';

# --- scalar context returns the cardinality ------------------------------
my $card = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4, 5]);
no_leaks_ok {
	eval { my $c = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4, 5]) }
} 'intersection: scalar count no leaks' unless $INC{'Devel/Cover.pm'};
is $card, 2, 'intersection returns the count in scalar context';

# --- UTF-8 wide chars match by string ------------------------------------
my @wide = intersection(["\x{263a}", "x"], ["\x{263a}", "y"]);
no_leaks_ok {
	eval { intersection(["\x{263a}", "x"], ["\x{263a}", "y"]) }
} 'intersection: wide chars no leaks' unless $INC{'Devel/Cover.pm'};
is_deeply \@wide, ["\x{263a}"], 'intersection matches identical wide-character strings';

# --- croak: no arguments -------------------------------------------------
my $e_zero = '';
eval { intersection(); 1 } or $e_zero = $@;
no_leaks_ok {
	eval { intersection() }
} 'intersection: empty croak no leaks' unless $INC{'Devel/Cover.pm'};
like $e_zero, qr/intersection needs >= 1 array ref/, 'intersection croaks with no args';

# --- croak: non-ref argument (real index, no stray %) --------------------
my $e_nonref = '';
eval { intersection([1, 2], 3); 1 } or $e_nonref = $@;
no_leaks_ok {
	eval { intersection([1, 2], 3) }
} 'intersection: non-ref croak no leaks' unless $INC{'Devel/Cover.pm'};
like $e_nonref, qr/argument index 1\b.*not an array reference/,
	'intersection croaks on a non-ref argument at the real index';
unlike $e_nonref, qr/%/,                                  'intersection non-ref croak leaves no literal % directive';

# --- croak: undef inside a ref (real indices, no stray %) ----------------
my $e_undef = '';
eval { intersection([1, undef, 3]); 1 } or $e_undef = $@;
no_leaks_ok {
	eval { intersection([1, undef, 3]) }
} 'intersection: undef croak no leaks' unless $INC{'Devel/Cover.pm'};
like   $e_undef, qr/array ref index 1 \(argument 0\)/, 'intersection croaks on an undef element with real indices';
unlike $e_undef, qr/%/,                                'intersection undef croak leaves no literal % directive';

done_testing();
