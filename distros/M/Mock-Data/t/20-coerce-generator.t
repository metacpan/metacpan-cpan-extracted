#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util 'coerce_generator';
use Scalar::Util 'reftype';

my @tests= (
	[ q( "a"                   ), 'a' ],
	[ q( '{a}'                 ), 'a_val' ],
	[ q( ['a']                 ), 'a' ],
	[ q( sub {'a'}             ), 'a' ],
	[ q( qr/(\w+)@(\w+)\.com/  ), qr/(\w+)@(\w+)\.com/ ],
	[ q( qr/(\w+)@(\w+)(\.com|\.org|\.net|\.co\.uk)/ ), qr/(\w+)@(\w+)(\.com|\.org|\.net|\.co\.uk)/ ],
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
		# eval is just so I can see the original code in the test name
		my $arg= eval $spec or die $@;
		my $gen= coerce_generator($arg);
		like( my $val= $gen->generate($mockdata), $result, "generates '$result'" );
		is( reftype($gen->compile), 'CODE', 'compiles to coderef' );
		like( $gen->compile->($mockdata), $result, "compiled generates '$result'" );
	};
}
