package Sub::Filter;

use warnings;
use strict;

use Test::More tests => 1 + 36*7;

BEGIN { use_ok "Sub::Filter"; }

our @activity;
sub f0 {
	die unless !wantarray && defined(wantarray);
	push @activity, [ "f0", [@_] ];
	return "f0x".$_[0]."f0y";
}
sub f1 {
	die unless !wantarray && defined(wantarray);
	push @activity, [ "f1", [@_] ];
	return "f1x".$_[0]."f1y";
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
	@want_out = ("o0", "o1");
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		my @got_out = ("ox", scalar($func->(@want_in)), "oy");
		is_deeply \@got_in, \@want_in;
		is_deeply \@got_out, [ "ox", $want_out[1], "oy" ];
		is_deeply \@activity, [];
	}
	mutate_sub_filter_return($func, \&f0);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		my @got_out = ("ox", scalar($func->(@want_in)), "oy");
		is_deeply \@got_in, \@want_in;
		is_deeply \@got_out, [ "ox", "f0x".$want_out[1]."f0y", "oy" ];
		is_deeply \@activity, [ [ "f0", [ $want_out[1] ] ] ];
	}
	mutate_sub_filter_return($func, \&f1);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		@activity = (); @got_in = (undef);
		my @got_out = ("ox", scalar($func->(@want_in)), "oy");
		is_deeply \@got_in, \@want_in;
		is_deeply \@got_out, [
			"ox", "f1xf0x".$want_out[1]."f0yf1y", "oy",
		];
		is_deeply \@activity, [
			[ "f0", [ $want_out[1] ] ],
			[ "f1", [ "f0x".$want_out[1]."f0y" ] ],
		];
	}
}

1;
