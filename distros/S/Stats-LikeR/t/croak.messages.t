#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

# croak() formats through perl's own engine, not the C library's, and that
# engine does not understand C99's 'z' length modifier: a "%zu" in a croak
# string reaches the user verbatim on perls that predate its support (5.10 and
# 5.12 both print it literally), so the number the message exists to report is
# the one thing it does not say.  These are the messages that carry an index or
# a count.  Each one is checked for the value it should name and then swept for
# any conversion left unexpanded, which is what catches the next one written
# with %zu, %lu or a bare %d on the wrong argument.

my @cases = (
	[ 'min, undef inside an array ref'   => sub { min(1, [2, undef]) },
	  qr/\Qmin: undefined value at array ref index 1 (argument 1)\E/ ],
	[ 'max, undef inside an array ref'   => sub { max(1, [2, undef]) },
	  qr/\Qmax: undefined value at array ref index 1 (argument 1)\E/ ],
	[ 'max, undef argument'              => sub { max(1, undef) },
	  qr/\Qmax: undefined value at argument index 1\E/ ],
	[ 'mode, undef inside an array ref'  => sub { mode(1, [2, undef]) },
	  qr/\Qmode: undefined value at array ref index 1 (argument 1)\E/ ],
	[ 'mode, undef argument'             => sub { mode(1, undef) },
	  qr/\Qmode: undefined value at argument index 1\E/ ],
	[ 'sum, undef inside an array ref'   => sub { sum(1, [2, undef]) },
	  qr/\Qsum: undefined value at array ref index 1 (argument 1)\E/ ],
	[ 'sum, undef argument'              => sub { sum(1, undef) },
	  qr/\Qsum: undefined value at argument index 1\E/ ],
	[ 'sd, undef inside an array ref'    => sub { sd(1, 2, [3, undef]) },
	  qr/\Qsd: undefined value at array ref index 1 (argument 2)\E/ ],
	[ 'sd, undef argument'               => sub { sd(1, 2, undef) },
	  qr/\Qsd: undefined value at argument index 2\E/ ],
	[ 'var, undef inside an array ref'   => sub { var(1, 2, [3, undef]) },
	  qr/\Qvar: undefined value at array ref index 1 (argument 2)\E/ ],
	[ 'var, undef argument'              => sub { var(1, 2, undef) },
	  qr/\Qvar: undefined value at argument index 2\E/ ],
	[ 'median, undef inside an array ref'=> sub { median(1, [2, undef]) },
	  qr/\Qmedian: undefined value at array ref index 1 (argument 1)\E/ ],
	[ 'median, undef argument'           => sub { median(1, undef) },
	  qr/\Qmedian: undefined value at argument index 1\E/ ],
	[ 'mcnemar_test, row is not an AoA'  => sub { mcnemar_test([ [1, 2], 'x' ]) },
	  qr/\Qmcnemar_test: row 1 is not an array ref\E/ ],
	[ 'friedman_test, row is not an AoA' => sub { friedman_test([ [1, 2, 3], 'x' ]) },
	  qr/\Qfriedman_test: row 1 is not an array ref\E/ ],
	[ 'hoa2hoh, undef in the key column' => sub { hoa2hoh({ id => [1, undef], v => [3, 4] }, 'id') },
	  qr/\Qhoa2hoh: key column 'id' has an undefined value at row 1\E/ ],
	[ 'oneway_test, one group in a hash' => sub { oneway_test({ a => [1, 2, 3] }) },
	  qr/\Qoneway_test: need at least 2 groups, got 1\E/ ],
	[ 'oneway_test, one group in an AoA' => sub { oneway_test([ [1, 2, 3] ]) },
	  qr/\Qoneway_test: need at least 2 groups, got 1\E/ ],
);

for my $case (@cases) {
	my ($name, $code, $want) = @$case;
	eval { $code->(); 1 };
	my $err = $@;
	ok($err, "$name: dies");
	like($err, $want, "$name: reports the value");
	unlike($err, qr/%[-+ 0-9.#]*(?:h|hh|l|ll|q|L|z|t|j)?[diouxXeEfgGaAcspn]/,
		"$name: no conversion left unexpanded");
}

done_testing();
