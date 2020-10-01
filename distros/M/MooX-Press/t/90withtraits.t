use strict;
use warnings;
use Test::More;
use Zydeco::Lite;

my $app = app sub {
	role generator "Foo" => sub {
		my ($gen, $n) = @_;
		method "foo" => sub { $n };
	};
	role "Bar" => sub {
		method "bar" => sub { 456 };
	};
	class "Thingy" => sub {
		method "baz" => sub { 789 };
	};
};

sub trimmit {
	local $_ = shift;
	s/^(main)?:://;
	$_;
}

my $obj = $app->get_class("Thingy", "Foo" => [123], "Bar")->new;

isa_ok( $obj, $app->get_class("Thingy"), '$obj' );
ok( $obj->does(trimmit $app->get_role("Bar")), '$obj->does(Bar)' );
is( $obj->foo, 123, '$obj->foo' );
is( $obj->bar, 456, '$obj->bar' );
is( $obj->baz, 789, '$obj->baz' );

done_testing;
