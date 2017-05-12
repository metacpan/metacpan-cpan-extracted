# This test is included to check that MooseX::RoleQR plays nice
# with other metaclass traits; not because the interaction with
# MooseX::ClassAttribute in particular is especially exciting.
#

use Test::More;

BEGIN {
	eval 'require MooseX::ClassAttribute; 1'
		or plan skip_all => 'requires MooseX::ClassAttribute';
}

my %X;

{
	package Local::QR1;
	use MooseX::RoleQR;
	use MooseX::ClassAttribute;
	class_has classy1 => (is => 'ro');
	before qr{^a} => sub { $X{$_[1]}++ };
}

{
	package Local::R1;
	use Moose::Role;
	use MooseX::ClassAttribute;
	class_has classy2 => (is => 'ro');
	before f => sub { $X{$_[1]}++ };
}

{
	package Local::C1;
	use Moose;
	use MooseX::ClassAttribute;
	with qw( Local::QR1 Local::R1 );
	class_has classy3 => (is => 'ro');
	sub a { 1 }
	sub f { 1 }
}

Local::C1->new->a('a'); $X{a}--;
is $X{a}, 0, "Class which composes a QR role and a regular role";

can_ok 'Local::C1' => qw( classy1 classy2 classy3 );

done_testing;

