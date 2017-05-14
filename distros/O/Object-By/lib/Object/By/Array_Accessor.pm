package Object::By::Array_Accessor;
use 5.8.1;
use strict;
use warnings;

sub THIS() { 0 }

sub P_POSITION() { 1 }
sub P_VALUE() { 2 }
sub _get
#(<object>)
{
	return($_[THIS][$_[P_POSITION]]);
};

sub _set
#(<object>, <value>)
{
	$_[THIS][$_[P_POSITION]] = $_[P_VALUE];
	return;
};

sub _get_or_set
#(<object> [, <value>])
{
	if ($#_ == 0) {
		return($_[THIS][$_[P_POSITION]]);
	} else {
		$_[THIS][$_[P_POSITION]] = $_[P_VALUE];
		return;
	}
};

1;
