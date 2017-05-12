use warnings;
use strict;

use Test::More tests => 1 + 2*9;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($env_0, $env_A, $env_B);
$env_0 = current_environment;
{ BEGIN { $^H |= 0x20000; $^H{foo} = "A"; } $env_A = current_environment; }
{
	BEGIN { $^H |= 0x20000; $^H{foo} = $main::b_av = ["B"]; }
	$env_B = current_environment;
}

my $have_runtime_hint_hash = "$]" >= 5.009004;

sub test_env_1() {
	push @main::activity, [
		1,
		($have_runtime_hint_hash ?
			(((caller(0))[10] || {})->{foo})
		: ()),
	];
}

sub test_env($$$$) {
	my($env, $override, $expect_comp, $expect_run) = @_;
	@main::activity = ();
	my $cv = parse_perl($env, q{
		}.(defined($override) ?
			"BEGIN { \$^H |= 0x20000; \$^H{foo} = $override; }"
		: "").q{
		BEGIN { push @main::activity, [0,$^H{foo}]; }
		main::test_env_1();
	});
	is_deeply \@main::activity, [[0,$expect_comp]];
	@main::activity = ();
	$cv->();
	is_deeply \@main::activity,
		[[ 1, ($have_runtime_hint_hash ? ($expect_run) : ()) ]];
}

test_env $env_0, undef, undef, undef;
test_env $env_A, undef, "A", "A";
test_env $env_B, undef, $main::b_av, "$main::b_av";
test_env $env_0, undef, undef, undef;

test_env $env_0, '"A"', "A", "A";
test_env $env_A, '"A"', "A", "A";
test_env $env_B, '"A"', "A", "A";

test_env $env_B, undef, $main::b_av, "$main::b_av";
test_env $env_B, '"A"', "A", "A";

1;
