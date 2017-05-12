use 5.010;
use MooseX::DeclareX
	plugins => [qw(build)],
	;

class Monkey
{
	build name { 'Anon' }
	build age returns (Num) { 0 }
	
	method screech ($sound) {
		say $self->name, q[: ], $sound;
	}
}

my $bob = Monkey->new(name => 'Bob');
$_ = Monkey->new;

$bob->screech("Owh!");
$_->screech("Eee!");

say $bob->age;