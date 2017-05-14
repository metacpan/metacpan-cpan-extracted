package Object::By::Array_Clone_Recursive;

use strict;
use warnings;

sub THIS() { 0 }

sub clone_constructor
#(<object>)
{
	my $this = $_[THIS];

	my @cloned = ();
	foreach my $attribute (@$this) {
		if (defined(Scalar::Util::blessed($attribute))) {
			push(@cloned, $attribute->clone_constructor);
		} else {
			push(@cloned, $attribute);
		}
	}

	my $cloned = \@cloned;
	bless($cloned, ref($_[THIS]));
	$cloned->_lock_object;

	return($cloned);
}

1;
