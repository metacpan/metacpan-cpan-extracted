use warnings;
no warnings "deprecated";
use strict;

BEGIN {
	if("$]" >= 5.015003 &&
			("$]" < 5.015005 || !(eval { require arybase; 1; }))) {
		require Test::More;
		Test::More::plan(skip_all => "no \$[ on this Perl");
	}
}

use Test::More tests => 13;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($env_0, $env_1, $env_2);

$env_0 = current_environment;
{ $[ = 1; $env_1 = current_environment; }
{ no warnings "void"; $[ = 2; $env_2 = current_environment; }

sub test_env($$$) {
	my($env, $override, $expect) = @_;
	@main::activity = ();
	parse_perl($env, q{
		}.(defined($override) ? "\$[ = $override;" : "").q{
		push @main::activity, [ (qw(a b c d e))[3], $[ ];
	})->();
	is_deeply \@main::activity, $expect;
}

test_env $env_0, undef, [[ "d", 0 ]];
test_env $env_1, undef, [[ "c", 1 ]];
test_env $env_2, undef, [[ "b", 2 ]];
test_env $env_0, undef, [[ "d", 0 ]];

test_env $env_0, 0, [[ "d", 0 ]];
test_env $env_1, 0, [[ "d", 0 ]];
test_env $env_2, 0, [[ "d", 0 ]];

test_env $env_0, 1, [[ "c", 1 ]];
test_env $env_1, 1, [[ "c", 1 ]];
test_env $env_2, 1, [[ "c", 1 ]];

test_env $env_2, 0, [[ "d", 0 ]];
test_env $env_2, 1, [[ "c", 1 ]];

1;
