use warnings;
use strict;

use Test::More tests => 10;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

@main::activity = ();
my $env = current_environment;
ok $env;
is_deeply \@main::activity, [];

@main::activity = ();
my $func = parse_perl($env, q{
	BEGIN { push @main::activity, "compiling"; }
	push @main::activity, "running";
	123;
});
ok $func;
is_deeply \@main::activity, ["compiling"];

@main::activity = ();
is $func->(), 123;
is_deeply \@main::activity, ["running"];

@main::activity = ();
is $func->(), 123;
is $func->(), 123;
is_deeply \@main::activity, ["running","running"];

1;
