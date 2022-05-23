use Test::More;
use strict;
use warnings;

subtest 'import' => sub {
	plan tests => 8;
	ok( 
		my $obj = do { eval q{
			package FooBar;
			use Moo;
			use MooX::Private::Attribute;
			has bar => ( is => 'rw', private => 1 );
			has public => ( is => 'rw' );
			sub foo { return $_[0]->bar(defined $_[1] ? $_[1] : ()); }
			1;
		}; 1; } && FooBar->new,
		q|my $obj = do { eval q{
			package FooBar;
			use Moo;
			use MooX::Private::Attribute;
			has bar => ( is => 'rw', private => 1 );
			sub foo { return $_[0]->bar(defined $_[1] ? $_[1] : ()); }
			1;
		}; 1; } && FooBar->new|
	);
	is( $obj->public('bar'), 'bar');
	is( $obj->foo, undef );
	is( $obj->foo('foo'), 'foo' );
	is( $obj->foo, 'foo' );
	ok( 
		my $obj2 = do { eval q{
			package FooBar::Boom;
			use Moo;
			extends 'FooBar';
			sub boom { return $_[0]->bar(defined $_[1] ? $_[1] : ()); }
			1;
		}; 1; } && FooBar::Boom->new,
		q|my $obj2 = do { eval q{
			package FooBar::Boom;
			use Moo;
			extends 'FooBar';
			sub boom { return $_[0]->bar(defined $_[1] ? $_[1] : ()); }
			1;
		}; 1; } && FooBar::Boom->new|
	);
	eval {
		$obj2->boom
	};
	like($@, qr/private/, 'private');
	eval {
		$obj2->bar
	};
	like($@, qr/private/, 'private');
};
done_testing();
