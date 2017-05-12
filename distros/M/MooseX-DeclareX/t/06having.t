# Tests an undocumented feature.
# I'm not sure the 'having' plugin is even a good idea.

use Test::More tests => 1;
use MooseX::DeclareX plugins => [qw(having std_constants)];

class Monkey having name
{
	has sleeping => (is => read_write, isa => 'Bool', required => true);
	method screech ($sound) {
		return $self->name . q[: ] . $sound;
	}
}

for ( Monkey->new(sleeping => 0, name => 'Bob') )
{
	ok (
		$_->screech('Eee!'),
		'Bob: Eee!',
	);
}
