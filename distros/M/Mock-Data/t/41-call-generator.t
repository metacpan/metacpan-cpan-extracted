#! /usr/bin/env perl
use Test2::V0;
use Mock::Data;

my (%gen_args, %gen_ret);
my $gen_a= sub { shift; @{ $gen_args{a} }= @_; return $gen_ret{a} };
my $gen_b= sub { shift; @{ $gen_args{b} }= @_; return $gen_ret{b} };
my $gen_c= sub { shift; @{ $gen_args{c} }= @_; return $gen_ret{c} };

my $mockdata= Mock::Data->new(
	generators => {
		a => $gen_a,
		b => [ $gen_b ],
		c => [ [ $gen_c ] ],
		d => '{a} {b {c}}',
	}
);

my @tests= (
	{
		gen_ret => { a => 'test' },
		call => [ 'a' ],
		output => 'test',
		gen_args => { a => [] },
	},
	{
		gen_ret => { b => 'test2' },
		call => [ 'b', { x => 1 } ],
		output => 'test2',
		gen_args => { b => [ { x => 1 } ] },
	},
	{
		gen_ret => { c => 'test3' },
		call => [ 'c', {}, 3, 2, 1 ],
		output => 'test3',
		gen_args => { c => [ {}, 3, 2, 1 ] },
	},
	{
		gen_ret => { a => 'A', b => 'B', c => 'C' },
		call => [ 'd', { z => 3 }, 'f' ],
		output => 'A B',
		gen_args => {
			a => [],
			b => ['C'],
			c => []
		},
	},
);
for my $t (@tests) {
	my $name= $t->{name} || _flatten_name($t->{call});
	%gen_ret= %{ $t->{gen_ret} }; # store the values that generators will return
	%gen_args= ();                # clear previous results
	subtest $name => sub {
		is( $mockdata->call(@{ $t->{call} }), $t->{output}, 'output' );
		is( \%gen_args, $t->{gen_args}, 'generator arguments' );
	};
}

sub _flatten_name {
	join ' ', map {
		!defined($_)? 'undef'
		: !ref($_)? $_
		: ref eq 'ARRAY'? '['._flatten_name(@$_).']'
		: ref eq 'HASH'? '{'._flatten_name(%$_).'}'
		: '?'
	} @_;
}

done_testing;
