use Test::More tests => 3;
use MooseX::DeclareX plugins => [qw(guard std_constants)];

class Monkey
{
	has sleeping => (is => read_write, isa => 'Bool', required => true);
	
	method screech ($sound) {
		$sound . "!";
	}
	
	# screech can only be called if monkey is awake
	guard screech {
		not $self->sleeping;
	}
}

for ( Monkey->new(sleeping => 0) )
{
	is(
		$_->screech('Aah'),
		'Aah!',
	);
	$_->sleeping(1);
	is(
		$_->screech('Owh'),
		undef,
	);
	$_->sleeping(0);
	is(
		$_->screech('Eee'),
		'Eee!',
	);
}
