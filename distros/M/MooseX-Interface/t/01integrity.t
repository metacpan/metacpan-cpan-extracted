use Test::More;
use Test::Exception;

lives_ok {
	package Local::Iface1;
	use MooseX::Interface;
	requires 'foo';
	one;
};

throws_ok {
	package Local::Iface2;
	use MooseX::Interface;
	requires 'foo';
	sub bar { 1 };
	one;
} qr{method defined within interface}i;

throws_ok {
	package Local::Iface3;
	use MooseX::Interface;
	requires 'foo';
	__PACKAGE__->meta->add_after_method_modifier(bar => sub { 1 });
	one;
} qr{method modifier defined within interface}i;

lives_ok {
	package Local::Iface4;
	use MooseX::Interface;
	requires 'foo';
	sub bar { 1 };
	# NOT: one
}; 

throws_ok {
	package Local::Class;
	use Moose;
	with qw( Local::Iface4 );
} qr{method defined within interface}i;

done_testing();

