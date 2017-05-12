use warnings;
use strict;

use Test::More tests => 5;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $env = current_environment;

@main::activity = ();
sub t0 () {
	my $v = parse_perl($env, q{
		push @main::activity, "a";
		return 123;
		push @main::activity, "b";
		456;
	})->();
	return $v + 1;
}
is t0(), 124;
is_deeply \@main::activity, ["a"];

@main::activity = ();
is parse_perl($env, q{
	$main::t1 = sub () {
		push @main::activity, "a";
		return 123;
		push @main::activity, "b";
		456;
	};
	push @main::activity, "x";
	$main::t1 = $main::t1->();
	push @main::activity, "y";
	$main::t1 + 1;
})->(), 124;
is_deeply \@main::activity, [qw(x a y)];

1;
