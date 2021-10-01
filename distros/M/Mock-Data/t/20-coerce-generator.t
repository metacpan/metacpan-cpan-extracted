#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util 'coerce_generator';
use Scalar::Util 'reftype';

my @tests= (
	[ q( "a"        ), 'a' ],
	[ q( '{a}'      ), 'a_val' ],
	[ q( ['a']      ), 'a' ],
	[ q( sub {'a'}  ), 'a' ],
);

plan scalar @tests;

{
	package Mock::Mock::Data;
	sub new { bless {}, shift; }
	sub generators {
		return { a => sub { 'a_val' } }
	}
	sub call {
		$_[0]->generators->{$_[1]}->(@_[2..$#_]);
	}
}

my $mockdata= Mock::Mock::Data->new;
for (@tests) {
	my ($spec, $result)= @$_;
	subtest "test $spec" => sub {
		my $arg= eval $spec or die $@;
		my $gen= coerce_generator($arg);
		is( $gen->generate($mockdata), $result, "generates '$result'" );
		is( reftype($gen->compile), 'CODE', 'compiles to coderef' );
		is( $gen->compile->($mockdata), $result, "compiled generates '$result'" );
	};
}
