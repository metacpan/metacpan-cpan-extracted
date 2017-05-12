use warnings;
use strict;

use Test::More tests => 19;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $env = current_environment;

my $fall_123 = parse_perl($env, "1,2,3");
is_deeply scalar($fall_123->()), 3;
is_deeply [$fall_123->()], [1,2,3];
is_deeply do { $fall_123->(); 456 }, 456;

my $return_123 = parse_perl($env, "return 1,2,3");
is_deeply scalar($return_123->()), 3;
is_deeply [$return_123->()], [1,2,3];
is_deeply do { $return_123->(); 456 }, 456;

my $context;
sub record_context() {
	$context = wantarray ? "ARRAY" : defined(wantarray) ? "SCALAR" : "VOID";
	return 123;
}

my $fall_rec = parse_perl($env, "record_context()");
$context = undef;
is_deeply scalar($fall_rec->()), 123;
is $context, "SCALAR";
$context = undef;
is_deeply [$fall_rec->()], [123];
is $context, "ARRAY";
$context = undef;
is_deeply do { $fall_rec->(); 456 }, 456;
is $context, "VOID";

my $return_rec = parse_perl($env, "return record_context()");
$context = undef;
is_deeply scalar($return_rec->()), 123;
is $context, "SCALAR";
$context = undef;
is_deeply [$return_rec->()], [123];
is $context, "ARRAY";
$context = undef;
is_deeply do { $return_rec->(); 456 }, 456;
is $context, "VOID";

1;
