use warnings;
use strict;

use Test::More tests => 12;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my $t0 = 0;
sub gen_t1() {
	my $t1 = 1000;
	return current_environment;
}
my $env_0 = gen_t1();
my $cv_0 = parse_perl($env_0, q{ [ $t0, $t1 ] });
my $cv_1 = parse_perl($env_0, q{ my $t2 = 2000; sub { [ $t0, $t1, $t2 ] } });
my $cv_2 = parse_perl($env_0, q{
	my $t2 = 2000;
	sub { [ ++$t0, ++$t1, ++$t2 ] };
});

is_deeply $cv_0->(), [ 0, 1000 ];
my $cv_3 = $cv_1->();
is_deeply $cv_3->(), [ 0, 1000, 2000 ];
is_deeply $cv_3->(), [ 0, 1000, 2000 ];
is_deeply $cv_0->(), [ 0, 1000 ];
is $t0, 0;
my $cv_4 = $cv_2->();
is_deeply $cv_4->(), [ 1, 1001, 2001 ];
is_deeply $cv_4->(), [ 2, 1002, 2002 ];
is_deeply $cv_3->(), [ 2, 1002, 2000 ];
is_deeply $cv_0->(), [ 2, 1002 ];
is $t0, 2;

$env_0 = undef;
$cv_0 = undef;
$cv_1 = undef;
$cv_2 = undef;
$cv_3 = undef;
is_deeply $cv_4->(), [ 3, 1003, 2003 ];

1;
