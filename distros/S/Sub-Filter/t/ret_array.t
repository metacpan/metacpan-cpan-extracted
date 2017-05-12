package Sub::Filter;

use warnings;
use strict;

use Test::More tests => 1 + 144*7;

BEGIN { use_ok "Sub::Filter"; }

our @activity;
sub f0 {
	die unless wantarray;
	push @activity, [ "f0", [@_] ];
	return ("f0x", @_, "f0y");
}
sub f1 {
	die unless wantarray;
	push @activity, [ "f1", [@_] ];
	return ("f1x", @_, "f1y");
}

our @got_in;
our @want_out;
sub test_p0 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	@want_out;
}
sub test_p1 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	(@want_out);
}
sub test_p2 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	return @want_out;
}
sub test_p3 {
	@got_in = ("ix", @_, "iy");
	die unless shift(@got_in) eq "ix";
	die unless pop(@got_in) eq "iy";
	return (@want_out);
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
		return @want_out;
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
		return (@want_out);
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
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		for(my $outlen = 0; $outlen != 4; $outlen++) {
			@want_out = map { "o".$_ } 0..$outlen-1;
			@activity = (); @got_in = (undef);
			my @got_out = ("ox", $func->(@want_in), "oy");
			is_deeply \@got_in, \@want_in;
			is_deeply \@got_out, [ "ox", @want_out, "oy" ];
			is_deeply \@activity, [];
		}
	}
	mutate_sub_filter_return($func, \&f0);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		for(my $outlen = 0; $outlen != 4; $outlen++) {
			@want_out = map { "o".$_ } 0..$outlen-1;
			@activity = (); @got_in = (undef);
			my @got_out = ("ox", $func->(@want_in), "oy");
			is_deeply \@got_in, \@want_in;
			is_deeply \@got_out,
				[ "ox", "f0x", @want_out, "f0y", "oy" ];
			is_deeply \@activity, [ [ "f0", \@want_out ] ];
		}
	}
	mutate_sub_filter_return($func, \&f1);
	for(my $inlen = 0; $inlen != 4; $inlen++) {
		my @want_in = map { "i".$_} 0..$inlen-1;
		for(my $outlen = 0; $outlen != 4; $outlen++) {
			@want_out = map { "o".$_ } 0..$outlen-1;
			@activity = (); @got_in = (undef);
			my @got_out = ("ox", $func->(@want_in), "oy");
			is_deeply \@got_in, \@want_in;
			is_deeply \@got_out, [
				"ox", "f1x", "f0x", @want_out,
				"f0y", "f1y", "oy",
			];
			is_deeply \@activity, [
				[ "f0", \@want_out ],
				[ "f1", [ "f0x", @want_out, "f0y" ] ],
			];
		}
	}
}

1;
