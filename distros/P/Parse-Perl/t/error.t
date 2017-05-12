use warnings;
use strict;

use Test::More tests => 23;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

eval "current_environment";
is $@, "";
eval "current_environment()";
is $@, "";
eval "current_environment(1)";
like $@, qr/\AToo many arguments /;
eval "&current_environment";
like $@, qr/\Acurrent_environment called as a function /;
eval "&current_environment()";
like $@, qr/\Acurrent_environment called as a function /;
eval "&current_environment(1)";
like $@, qr/\Acurrent_environment called as a function /;

my $env = current_environment;
foreach my $val (
	undef,
	*STDOUT,
	\"",
	[],
	sub{},
	bless({},"main"),
) {
	eval { parse_perl($env, $val) };
	like $@, qr/\Asource is not a string /;
}

foreach my $val (
	undef,
	"",
	"abc",
	*STDOUT,
	\"",
	{},
	sub{},
	bless([],"main"),
	bless({},"Parse::Perl::Environment"),
) {
	eval { parse_perl($val, "123") };
	like $@, qr/\Aenvironment is not an environment object /;
}

eval { parse_perl(bless([],"Parse::Perl::Environment"), "123") };
like $@, qr/\Amalformed /;

1;
