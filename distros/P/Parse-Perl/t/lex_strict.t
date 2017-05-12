use warnings;
use strict;

use Test::More tests => 1 + 2*7;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($env_strict, $env_sloppy);

$env_strict = current_environment;
{ no strict; $env_sloppy = current_environment; }

sub test_env($$$$) {
	my($env, $override, $expect_act, $expect_err) = @_;
	@main::activity = ();
	eval {
		parse_perl($env, q{
			}.(defined($override) ? "$override strict;" : "").q{
			push @main::activity, 1;
			$main::foo = ${"main::foo"};
			push @main::activity, 2;
		})->();
	};
	my $err = $@;
	is_deeply \@main::activity, $expect_act;
	like $err, $expect_err;
}

test_env $env_strict, undef, [1], qr/\ACan't use string /;
test_env $env_sloppy, undef, [1,2], qr/\A\z/;
test_env $env_strict, undef, [1], qr/\ACan't use string /;

test_env $env_strict, "use", [1], qr/\ACan't use string /;
test_env $env_sloppy, "use", [1], qr/\ACan't use string /;

test_env $env_strict, "no", [1,2], qr/\A\z/;
test_env $env_sloppy, "no", [1,2], qr/\A\z/;

1;
