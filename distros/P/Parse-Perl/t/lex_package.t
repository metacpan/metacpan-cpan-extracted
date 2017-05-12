use warnings;
no warnings "deprecated";
use strict;

use Test::More tests => 19;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

{
	package main;
	$main::env_m = main::current_environment;
	sub pkgname0() { "main" }
	sub pkgname1 { $main::pkgname1 = undef; return "main"; }
}

{
	package A;
	$main::env_A = main::current_environment;
	sub pkgname0() { "A" }
	sub pkgname1 { $main::pkgname1 = undef; return "A"; }
}

{
	package B;
	$main::env_B = main::current_environment;
	sub pkgname0() { "B" }
	sub pkgname1 { $main::pkgname1 = undef; return "B"; }
}

sub test_env($$$) {
	my($env, $override, $expect) = @_;
	@main::activity = ();
	parse_perl($env, q{
		}.(defined($override) ? "package $override;" : "").q{
		push @main::activity, [ __PACKAGE__, pkgname0(), pkgname1() ];
	})->();
	is_deeply \@main::activity, $expect;
}

test_env $main::env_m, undef, [[qw(main main main)]];
test_env $main::env_A, undef, [[qw(A A A)]];
test_env $main::env_B, undef, [[qw(B B B)]];
test_env $main::env_m, undef, [[qw(main main main)]];

test_env $main::env_m, "A", [[qw(A A A)]];
test_env $main::env_A, "A", [[qw(A A A)]];
test_env $main::env_B, "A", [[qw(A A A)]];

test_env $main::env_m, "B", [[qw(B B B)]];
test_env $main::env_A, "B", [[qw(B B B)]];
test_env $main::env_B, "B", [[qw(B B B)]];

test_env $main::env_B, "main", [[qw(main main main)]];
test_env $main::env_B, "A", [[qw(A A A)]];

sub test_env_n($$$) {
	my($env, $override, $expect) = @_;
	@main::activity = ();
	parse_perl($env, q{
		}.(defined($override) ? "package $override;" : "").q{
		push @main::activity, [ __PACKAGE__ ];
	})->();
	is_deeply \@main::activity, $expect;
}

SKIP: {
	skip "package not nullable on this Perl", 6 unless "$]" < 5.009;
	eval q{
		package;
		$main::env_0 = main::current_environment;
	}; die $@ if $@ ne "";
	test_env $main::env_0, "A", [[qw(A A A)]];
	test_env $main::env_0, "main", [[qw(main main main)]];
	test_env_n $main::env_0, undef, [[undef]];
	test_env_n $main::env_0, "", [[undef]];
	test_env_n $main::env_m, "", [[undef]];
	test_env_n $main::env_A, "", [[undef]];
}

1;
