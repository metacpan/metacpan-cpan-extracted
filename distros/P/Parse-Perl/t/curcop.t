use warnings;
use strict;

use Test::More tests => 2;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

{ package Foo; $main::env = main::current_environment; }

{
	package Bar;
	main::is_deeply [
		ref(bless({})),
		ref(main::parse_perl($main::env, "123")),
		ref(bless({})),
	], [qw(Bar CODE Bar)];
}

1;
