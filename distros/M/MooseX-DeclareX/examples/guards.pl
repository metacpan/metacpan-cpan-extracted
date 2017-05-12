use 5.010;
use MooseX::DeclareX
	plugins => [qw(guard)],
	;

class Monkey
{
	has sleeping => (is => 'rw', isa => 'Bool', required => 1);
	
	method screech ($sound) {
		say $sound;
	}
	
	# screech can only be called if monkey is awake
	guard screech {
		not $self->sleeping;
	}
}

for ( Monkey->new(sleeping => 0) )
{
	$_->screech('Aah!');
	$_->sleeping(1);
	$_->screech('Owh!');  # says nothing!!
	$_->sleeping(0);
	$_->screech('Eee!');
}
