package Sub::Filter;

use warnings;
use strict;

use Test::More tests => 1 + 24*7;

BEGIN { use_ok "Sub::Filter"; }

our @activity;
sub f0 {
	die unless !defined(wantarray);
	push @activity, [ "f0", [@_] ];
	return;
}

our @got_in;
our @want_out;
sub test_p0 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	$want_out[0], $want_out[1];
}
sub test_p1 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	($want_out[0], $want_out[1]);
}
sub test_p2 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	return $want_out[0], $want_out[1];
}
sub test_p3 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	return ($want_out[0], $want_out[1]);
}
our $true = 1;
our $junk;
sub test_p4 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	my $z = 1;
	if($true) {
		my $y = 2;
		$junk = $z + $y;
		return $want_out[0], $want_out[1];
	} else {
		$junk = $z + 123;
	}
	$junk++;
}
sub test_p5 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	my $z = 1;
	if($true) {
		my $y = 2;
		$junk = $z + $y;
		return ($want_out[0], $want_out[1]);
	} else {
		$junk = $z + 123;
	}
	$junk++;
}

foreach my $func (
	\&test_p0,
	\&test_p1,
	\&test_p2,
	\&test_p3,
	\&test_p4,
	\&test_p5,
	\&_test_xs,
) {
	my $main = eval q{ sub { } };
	@want_out = ("o0", "o1");
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		$main->(@want_in);
		is_deeply \@got_in, [undef];
		is_deeply \@activity, [];
	}
	mutate_sub_filter_return($main, $func);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		$main->(@want_in);
		is_deeply \@got_in, [];
		is_deeply \@activity, [];
	}
	mutate_sub_filter_return($main, \&f0);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		$main->(@want_in);
		is_deeply \@got_in, [];
		is_deeply \@activity, [ [ "f0", [] ] ];
	}
}

1;
