use Test::More;

my %X;

{
	package Local::QR1;
	use MooseX::RoleQR;
	before qr{^a} => sub { $X{$_[1]}++ };
}

{
	package Local::R1;
	use Moose::Role;
	before f => sub { $X{$_[1]}++ };
}

{
	package Local::C1;
	use Moose;
	with qw( Local::QR1 Local::R1 );
	sub a { 1 }
	sub f { 1 }
}

Local::C1->new->a('a'); $X{a}--;
is $X{a}, 0, "Class which composes a QR role and a regular role";

{
	package Local::QR2;
	use MooseX::RoleQR;
	before qr{^b} => sub { $X{$_[1]}++ };
}

{
	package Local::C2;
	use Moose;
	with qw( Local::QR1 Local::QR2 );
	sub a { 1 }
	sub b { 1 }
}

Local::C2->new->a('a'); $X{a}--;
Local::C2->new->b('b'); $X{b}--;
ok($X{a}==0 && $X{b}==0, "Class which composes two QR roles");

{
	package Local::QR3;
	use MooseX::RoleQR;
	with qw( Local::QR1 Local::QR2  Local::R2 );
	before qr{^c$} => sub { $X{$_[1]}++ };
}

{
	package Local::R2;
	use Moose::Role;
	before g => sub { $X{$_[1]}++ };
}

{
	package Local::C3;
	use Moose;
	with qw( Local::QR3 Local::R2 );
	sub a { 1 }
	sub b { 1 }
	sub c { 1 }
	sub g { 1 }
	sub xyzzy { 1 };
}

Local::C3->new->a('a'); $X{a}--;
Local::C3->new->b('b'); $X{b}--;
Local::C3->new->c('c'); $X{c}--;
Local::C3->new->g('g'); $X{g}--;
Local::C3->new->xyzzy('xyzzy');

ok(
	$X{a}==0 &&
	$X{b}==0 &&
	$X{c}==0 &&
	$X{g}==0 &&
	!exists $X{xyzzy},
	"Class with complex composition",
);

note explain \%X;
done_testing;

