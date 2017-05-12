use warnings;
use strict;

use Test::More tests => 7;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $t0 = 0;
my $env_0 = parse_perl(current_environment, q{
	my $t1 = 1000;
	current_environment;
})->();

my $cv_0 = parse_perl($env_0, q{ [ $t0, $t1 ] });
is_deeply $cv_0->(), [ 0, 1000 ];

my $cv_1 = parse_perl($env_0, q{ my $t2 = 2000; current_environment });
my $cv_2 = parse_perl($cv_1->(), q{ [ ++$t0, ++$t1, ++$t2 ] });

is_deeply $cv_2->(), [ 1, 1001, 2001 ];
is_deeply $cv_2->(), [ 2, 1002, 2002 ];
is_deeply $cv_0->(), [ 2, 1002 ];
is $t0, 2;

$env_0 = undef;
$cv_0 = undef;
$cv_1 = undef;
is_deeply $cv_2->(), [ 3, 1003, 2003 ];

1;
