use warnings;
use strict;

use Test::More tests => 7;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $env = current_environment;

my $empty = parse_perl($env, "");
is_deeply scalar($empty->()), undef;
is_deeply [$empty->()], [];
is_deeply do { $empty->(); 123 }, 123;

my $stub = parse_perl($env, "()");
is_deeply scalar($stub->()), undef;
is_deeply [$stub->()], [];
is_deeply do { $stub->(); 123 }, 123;

1;
