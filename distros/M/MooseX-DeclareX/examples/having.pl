use 5.010;
use MooseX::DeclareX
	plugins => [qw(guard having)],
	;

class Monkey having name
{
	has sleeping => (is => 'rw', isa => 'Bool', required => 1);
	
	method screech ($sound) {
		say $sound;
	}
}

for ( Monkey->new(sleeping => 0, name => 'Bob') )
{
	$_->screech('Eee! ' . $_->name);
}
