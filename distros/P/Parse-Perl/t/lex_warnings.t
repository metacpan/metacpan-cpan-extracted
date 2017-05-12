# no "use warnings" here, so that the default state can be captured below
use strict;

use Test::More tests => 1 + 2*23;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($env_std, $env_all, $env_none, $env_onlyvoid, $env_allbutvoid);

$env_std = current_environment;
{ use warnings; $env_all = current_environment; }
{ no warnings; $env_none = current_environment; }
{ no warnings; use warnings "void"; $env_onlyvoid = current_environment; }
{ use warnings; no warnings "void"; $env_allbutvoid = current_environment; }

$SIG{__WARN__} = sub {
	$_[0] =~ /\A([^ \n]*)/;
	push @main::warnings, $1;
};

sub test_env($$$) {
	my($env, $override, $expect) = @_;
	@main::activity = ();
	@main::warnings = ();
	parse_perl($env, q{
		}.(defined($override) ? "$override warnings;" : "").q{
		123;
		$main::foo = "a" + 1;
		push @main::activity, 1;
	})->();
	is_deeply \@main::activity, [1];
	is_deeply [ sort @main::warnings ], [ sort @$expect ];
}

$^W = 0;
test_env $env_std, undef, [];
test_env $env_all, undef, [qw(Useless Argument)];
test_env $env_none, undef, [];
test_env $env_onlyvoid, undef, [qw(Useless)];
test_env $env_allbutvoid, undef, [qw(Argument)];
$^W = 1;
test_env $env_std, undef, [qw(Useless Argument)];
test_env $env_all, undef, [qw(Useless Argument)];
test_env $env_none, undef, [];
test_env $env_onlyvoid, undef, [qw(Useless)];
test_env $env_allbutvoid, undef, [qw(Argument)];
$^W = 0;
test_env $env_std, undef, [];

test_env $env_std, "use", [qw(Useless Argument)];
test_env $env_all, "use", [qw(Useless Argument)];
test_env $env_none, "use", [qw(Useless Argument)];
test_env $env_onlyvoid, "use", [qw(Useless Argument)];
test_env $env_allbutvoid, "use", [qw(Useless Argument)];

test_env $env_std, "no", [];
test_env $env_all, "no", [];
test_env $env_none, "no", [];
test_env $env_onlyvoid, "no", [];
test_env $env_allbutvoid, "no", [];

test_env $env_allbutvoid, "use", [qw(Useless Argument)];
test_env $env_allbutvoid, "no", [];

1;
