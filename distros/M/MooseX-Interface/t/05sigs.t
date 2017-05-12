use Test::More tests => 5;
use Test::Exception;

{
	package Local::Iface;
	use MooseX::Interface;
	requires add => [qw( Int Int )];
	one;
}

{
	package Local::Impl;
	use Moose;
	with qw(Local::Iface);
	sub add { $_[1] + $_[2] };
}

my $o = Local::Impl->new;

is( $o->add(4,5), 9, 'arguments which pass signature check are ok' );
is( $o->add(9,5,"blah"), 14, 'additional arguments are ignored' );

throws_ok { $o->add("Hello", "World") } qr{did not conform to signature};
throws_ok { $o->add("Hello", 2) } qr{did not conform to signature};
throws_ok { $o->add(2, "World") } qr{did not conform to signature};
