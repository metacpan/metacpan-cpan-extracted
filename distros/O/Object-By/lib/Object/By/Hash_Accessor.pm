package Object::By::Hash_Accessor;

use strict;
use warnings;

sub THIS() { 0 };

sub P_NAME() { 1 }
sub P_VALUE() { 2 }
sub _get
#(<object>)
{
	return($_[THIS]{$_[P_NAME]});
};

sub _set
#(<object>, <value>)
{
	$_[THIS]{$_[P_NAME]} = $_[P_VALUE];
	return;
};

sub _get_or_set
#(<object> [, <value>])
{
	if ($#_ == 0) {
		return($_[THIS]{$_[P_NAME]});
	} else {
		$_[THIS]{$_[P_NAME]} = $_[P_VALUE];
		return;
	}
};

1;
