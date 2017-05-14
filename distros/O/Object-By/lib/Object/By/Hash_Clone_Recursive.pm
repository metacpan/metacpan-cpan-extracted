package Object::By::Hash_Clone_Recursive;

use strict;
use warnings;
use Scalar::Util qw();

sub THIS() { 0 }

sub clone_constructor
#(<object>)
{
	my $this = $_[THIS];

	my $cloned = {};
	keys(%$this); # reset 'each' iterator
	while (my ($key, $value) = each(%$this)) {
		if (defined(Scalar::Util::blessed($value))) {
			$cloned->{$key} = $value->clone_constructor;
		} else {
			$cloned->{$key} = $value;
		}
	}
	bless($cloned, ref($_[THIS]));
	$cloned->_lock_object;

	return($cloned);
}

1;
