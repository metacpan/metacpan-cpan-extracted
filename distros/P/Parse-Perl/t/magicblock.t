use warnings;
use strict;

use Test::More tests => 5;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

$SIG{__WARN__} = sub {
	my $warn = $_[0];
	$warn =~ s/ at .*//s;
	push @main::activity, "WARNING: $warn";
};

my $have_unitcheck = "$]" >= 5.009005;

@main::activity = ();
my $func = parse_perl(current_environment, q{
	BEGIN { push @main::activity, "begin 0"; }
	CHECK { push @main::activity, "check 0"; }
	END { push @main::activity, "end 0"; }
	INIT { push @main::activity, "init 0"; }
	}.($have_unitcheck ?
		q{UNITCHECK { push @main::activity, "unitcheck 0"; }}
	: "").q{
	push @main::activity, "running";
	}.($have_unitcheck ?
		q{UNITCHECK { push @main::activity, "unitcheck 1"; }}
	: "").q{
	INIT { push @main::activity, "init 1"; }
	END { push @main::activity, "end 1"; }
	CHECK { push @main::activity, "check 1"; }
	BEGIN { push @main::activity, "begin 1"; }
	123;
});
is_deeply \@main::activity, [
	"begin 0",
	"WARNING: Too late to run CHECK block",
	"WARNING: Too late to run INIT block",
	"WARNING: Too late to run INIT block",
	"WARNING: Too late to run CHECK block",
	"begin 1",
	($have_unitcheck ? (
		"unitcheck 1",
		"unitcheck 0",
	) : ()),
];

@main::activity = ();
is $func->(), 123;
is_deeply \@main::activity, ["running"];

@main::activity = ();
END { is_deeply \@main::activity, [ "end 1", "end 0" ]; }

1;
