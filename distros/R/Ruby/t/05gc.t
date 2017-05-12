#!perl

use warnings;
use strict;

use Test::More tests => 89;

use constant DEBUG => 0;
use constant N     => 100;

END{ pass "test end" }


BEGIN{ use_ok('Ruby', ':DEFAULT', 'lambda(&)', 'rb_c', 'rb_m') }

use Ruby -class => qw(GC Hash Array);

#use constant GC     => rb_m GC;
#use constant Hash   => rb_c Hash;
#use constant Array  => rb_c Array;

{
	package T;

	my $count = 0;
	sub new{ $count++;bless do{ my $o=$count; \$o } };
	sub DESTROY{
		Carp::carp "#DESTROY $count" if main::DEBUG;
		$count--;
	}

	sub inspect{ "T:${$_[0]}" };

	sub id{ ${$_[0]} }

	sub count{ $count }
}

sub Dump{
	require Devel::Peek;
	&Devel::Peek::Dump;
}


use Ruby -eval => <<'.';

def perl_ary_push(ary, val)
	a = Perl::Array.new;
	a.push(val, Perl::String("foo"), "bar");

	ary.push(a);
end

def empty()
end
.

sub gctest{

	my $o = Hash->new();

	for(1 .. N){
		GC->start;
		my $a = Array->new();
		my $t = T->new;
		my $l = lambda{ $t };
	}

	GC->start;

	cmp_ok(T->count, '<=', 4, 'new & gc');

	my $lambda;
	my @ary;
	for(1 .. N){
		my $h = Hash->new();
		my $a = Array->new();

		my $i = $_;
		$lambda = lambda { is $i, N, "lambda->()" };

		perl_ary_push(\@ary, T->new);
	}

	GC->start;

	for(my $i = 0; $i < 5; $i++){
		is ref($ary[$i]), 'ARRAY', "push in ruby";
		isa_ok $ary[$i][0], 'T';

		is $ary[$i][1], "foo", "scalar is alive"; # new scalar

		is $ary[$i][2], "bar", "str is alive"; # ruby str
	}

	cmp_ok(T->count - N, "<=", 2, "T->count is about ".N)
;
	@ary = ();

	GC->start;

	$lambda->(); # lambda { is $i, N, "lambda->()" };

	GC->start;

	$lambda->();

	cmp_ok(T->count, '<=', 2, "start, T->count is zero (or 1)");


	{
		my @a;
		for(1 .. N){
			my $h = Hash->new;
			push @a, $h;

			$h->store('foo', T->new());
		}

		cmp_ok(T->count - N, '<=', 2, "T's object is alive (befor GC)");

		GC->start;

		cmp_ok(T->count - N, '<=', 2, "T's object is alive (after GC)");

	}


	GC->start;

	ok($o->kind_of('Hash'), "alive object");

}
cmp_ok(T->count, "<=", 0, "<STATRT> first test (tolerable error: 0)");

gctest();

cmp_ok(T->count, "<=", 4, "<STATRT> second test (tolerable error: 3)");

gctest();

cmp_ok(T->count, "<=", 4, "<STATRT> third test (tolerable error: 3)");

gctest();



