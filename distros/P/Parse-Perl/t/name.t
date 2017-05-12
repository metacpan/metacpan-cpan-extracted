use warnings;
use strict;

BEGIN {
	eval { require Sub::Identify };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Sub::Identify not available");
	}
	Sub::Identify->import(qw(sub_fullname));
}

use Test::More tests => 3;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $env_main = current_environment;
my $env_foo = do { package Foo; main::current_environment };
my $anon_main = sub { 123 };
my $anon_foo = do { package Foo; sub { 123 } };

is sub_fullname(parse_perl($env_main, "123")), sub_fullname($anon_main);
is sub_fullname(parse_perl($env_foo, "123")), sub_fullname($anon_foo);

1;
