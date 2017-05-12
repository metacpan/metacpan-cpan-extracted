use warnings;
use strict;

use Test::More tests => 1 + 8*3;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $func = parse_perl(current_environment, '[@_]');

sub test_args {
	my $targs = [@_];
	is_deeply &$func, $targs;
	is_deeply [@_], $targs;
	is_deeply $func->(), [];
	is_deeply [@_], $targs;
	is_deeply $func->(1,2,3), [1,2,3];
	is_deeply [@_], $targs;
	is_deeply &$func, $targs;
	is_deeply [@_], $targs;
}

test_args();
test_args(qw(x));
test_args(qw(y z));

1;
