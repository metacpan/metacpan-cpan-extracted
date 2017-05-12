use warnings;
use strict;

use Test::More tests => 134;
BEGIN { use_ok "Parse::Perl", qw(current_environment parse_perl); }

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($env_a, $env_b, $env_c, $env_d, $cv_a, $cv_b, $cv_c, $cv_d);

sub multi_compile($) {
	my($source) = @_;
	$cv_a = eval { parse_perl($env_a, $source) } || $@;
	$cv_b = eval { parse_perl($env_b, $source) } || $@;
	$cv_c = eval { parse_perl($env_c, $source) } || $@;
	$cv_d = eval { parse_perl($env_d, $source) } || $@;
}

my $t0 = 0;
$env_a = current_environment;
my $t1 = 1000;
$env_b = current_environment;
my $t2 = (($env_c = current_environment), 2000);
$env_d = current_environment;

multi_compile(q{$t0});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 0;
is $cv_b->(), 0;
is $cv_c->(), 0;
is $cv_d->(), 0;

multi_compile(q{++$t0});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 1;
is $cv_b->(), 2;
is $cv_c->(), 3;
is $cv_d->(), 4;
is $t0, 4;

multi_compile(q{++$t1});
like $cv_a, qr/\AGlobal symbol "\$t1"/;
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_b->(), 1001;
is $cv_c->(), 1002;
is $cv_d->(), 1003;
is $t1, 1003;

multi_compile(q{++$t2});
like $cv_a, qr/\AGlobal symbol "\$t2"/;
like $cv_b, qr/\AGlobal symbol "\$t2"/;
like $cv_c, qr/\AGlobal symbol "\$t2"/;
is ref($cv_d), "CODE";
is $cv_d->(), 2001;
is $t2, 2001;

sub gen_t3() {
	my $t3 = 3000;
	my $e0 = current_environment;
	my $t4 = 4000;
	my $e1 = current_environment;
	return ($e0, $e1);
}
($env_a, $env_b) = gen_t3();
($env_c, $env_d) = gen_t3();

multi_compile(q{$t2});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 2001;
is $cv_b->(), 2001;
is $cv_c->(), 2001;
is $cv_d->(), 2001;

multi_compile(q{++$t2});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 2002;
is $cv_b->(), 2003;
is $cv_c->(), 2004;
is $cv_d->(), 2005;
is $t2, 2005;

multi_compile(q{++$t3});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 3001;
is $cv_b->(), 3002;
is $cv_c->(), 3001;
is $cv_d->(), 3002;
is $cv_a->(), 3003;
is $cv_b->(), 3004;
is $cv_c->(), 3003;
is $cv_d->(), 3004;

multi_compile(q{++$t4});
like $cv_a, qr/\AGlobal symbol "\$t4"/;
is ref($cv_b), "CODE";
like $cv_c, qr/\AGlobal symbol "\$t4"/;
is ref($cv_d), "CODE";
is $cv_b->(), 4001;
is $cv_d->(), 4001;
is $cv_b->(), 4002;
is $cv_d->(), 4002;

multi_compile(q{defined($e0)});
like $cv_a, qr/\AGlobal symbol "\$e0"/;
is ref($cv_b), "CODE";
like $cv_c, qr/\AGlobal symbol "\$e0"/;
is ref($cv_d), "CODE";
ok $cv_b->();
ok $cv_d->();

multi_compile(q{defined($e1)});
like $cv_a, qr/\AGlobal symbol "\$e1"/;
like $cv_b, qr/\AGlobal symbol "\$e1"/;
like $cv_c, qr/\AGlobal symbol "\$e1"/;
like $cv_d, qr/\AGlobal symbol "\$e1"/;

sub gen_t5() {
	my $t5 = 5000;
	return sub {
		my $t6 = 6000;
		return current_environment;
	}
}
my $u_x = gen_t5();
my $u_y = gen_t5();
$env_a = $u_x->();
$env_b = $u_x->();
$env_c = $u_y->();
$env_d = $u_y->();

multi_compile(q{$t2});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 2005;
is $cv_b->(), 2005;
is $cv_c->(), 2005;
is $cv_d->(), 2005;

multi_compile(q{++$t2});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 2006;
is $cv_b->(), 2007;
is $cv_c->(), 2008;
is $cv_d->(), 2009;
is $t2, 2009;

multi_compile(q{++$t3});
like $cv_a, qr/\AGlobal symbol "\$t3"/;
like $cv_b, qr/\AGlobal symbol "\$t3"/;
like $cv_c, qr/\AGlobal symbol "\$t3"/;
like $cv_d, qr/\AGlobal symbol "\$t3"/;

multi_compile(q{++$t5});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 5001;
is $cv_b->(), 5002;
is $cv_c->(), 5001;
is $cv_d->(), 5002;
is $cv_a->(), 5003;
is $cv_b->(), 5004;
is $cv_c->(), 5003;
is $cv_d->(), 5004;

multi_compile(q{++$t6});
is ref($cv_a), "CODE";
is ref($cv_b), "CODE";
is ref($cv_c), "CODE";
is ref($cv_d), "CODE";
is $cv_a->(), 6001;
is $cv_b->(), 6001;
is $cv_c->(), 6001;
is $cv_d->(), 6001;
is $cv_a->(), 6002;
is $cv_a->(), 6003;
is $cv_a->(), 6004;
is $cv_b->(), 6002;
is $cv_b->(), 6003;
is $cv_c->(), 6002;
is $cv_a->(), 6005;
is $cv_b->(), 6004;
is $cv_c->(), 6003;
is $cv_d->(), 6002;

$cv_a = parse_perl($env_a, q{
	my $t5 = 5555;
	my $t7 = 7777;
	[ $t5, $t6, $t7 ];
});
is_deeply $cv_a->(), [ 5555, 6005, 7777 ];
is_deeply $cv_a->(), [ 5555, 6005, 7777 ];

$cv_a = parse_perl($env_a, q{
	my $t5 = 5555;
	my $t7 = 7777;
	[ ++$t5, ++$t6, ++$t7 ];
});
is_deeply $cv_a->(), [ 5556, 6006, 7778 ];
is_deeply $cv_a->(), [ 5556, 6007, 7778 ];

1;
