use warnings;
use strict;

use Test::More tests => 1 + 31*4 + 31*4 + 14*20;

use_ok "Scalar::String", qw(
	sclstr_is_upgraded sclstr_is_downgraded
	sclstr_upgrade_inplace sclstr_downgrade_inplace
	sclstr_upgraded sclstr_downgraded
);

foreach my $tstr (
	"",
	"abc",
	"a\x00b\x7fc",
	"a"x40000,
) {
	my @u = (sclstr_upgraded($tstr));
	my @d = (sclstr_downgraded($tstr));
	push @u, map { sclstr_upgraded($_) } $u[0], $d[0];
	push @u, map { my $s = $_; sclstr_upgrade_inplace($s); $s }
			$u[0], $d[0];
	push @d, map { my $s = $_; sclstr_downgrade_inplace($s); $s }
			$u[0], $d[0];
	push @d, map { sclstr_downgraded($_) } $u[0], $d[0];
	foreach(@u) {
		ok sclstr_is_upgraded($_);
		ok !sclstr_is_downgraded($_);
		ok $_ eq $u[0];
	}
	foreach(@d) {
		ok !sclstr_is_upgraded($_);
		ok sclstr_is_downgraded($_);
		ok $_ eq $d[0];
	}
	ok $u[0] eq $d[0];
}

foreach my $tstr (
	"\xc2\x80",
	"\x80abc\xff",
	"\xffabc\x80",
	("a"x40000)."\x80",
) {
	my @u = (sclstr_upgraded($tstr));
	my @d = (sclstr_downgraded($tstr));
	push @u, map { sclstr_upgraded($_) } $u[0], $d[0];
	push @d, map { sclstr_downgraded($_) } $u[0], $d[0];
	push @u, map { my $s = $_; sclstr_upgrade_inplace($s); $s }
			$u[0], $d[0];
	push @d, map { my $s = $_; sclstr_downgrade_inplace($s); $s }
			$u[0], $d[0];
	foreach(@u) {
		ok sclstr_is_upgraded($_);
		ok !sclstr_is_downgraded($_);
		ok $_ eq $u[0];
	}
	foreach(@d) {
		ok !sclstr_is_upgraded($_);
		ok sclstr_is_downgraded($_);
		ok $_ eq $d[0];
	}
	ok ord($u[0]) == ord($d[0]);
}

no warnings "utf8";
foreach my $tstr (
	"abc\x{100}xyz",
	"abc\x{d7ff}xyz",
	"abc\x{d800}xyz",
	"abc\x{dfff}xyz",
	"abc\x{e000}xyz",
	"abc\x{fdd0}xyz",
	"abc\x{fffd}xyz",
	"abc\x{fffe}xyz",
	"abc\x{ffff}xyz",
	"abc\x{10000}xyz",
	"abc\x{1fffd}xyz",
	"abc\x{1fffe}xyz",
	"abc\x{1ffff}xyz",
	"abc\x{20000}xyz",
	"abc\x{10fffd}xyz",
	"abc\x{10fffe}xyz",
	"abc\x{10ffff}xyz",
	"abc\x{110000}xyz",
	"abc\x{7fffffff}xyz",
	("a"x40000)."\x{100}",
) {
	my @u = ($tstr);
	push @u, sclstr_upgraded($u[0]);
	eval { sclstr_downgraded($u[0]) }; isnt $@, "";
	eval { sclstr_downgrade_inplace($u[0]) }; isnt $@, "";
	push @u, sclstr_downgraded($u[0], 1);
	push @u, do { my $s = $u[0]; sclstr_downgrade_inplace($s, 1); $s };
	foreach(@u) {
		ok sclstr_is_upgraded($_);
		ok !sclstr_is_downgraded($_);
		ok $_ eq $u[0];
	}
}

1;
