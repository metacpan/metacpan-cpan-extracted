package Object::By::Scalar;

use strict;
use warnings;

sub THIS() { 0 }

sub P_CLASS() { 0 }
sub P_VALUE() { 1 }
sub constructor
#(<class> [, <value>], ...)
{
	my $value = undef;
	my $this = bless(\$value, shift(@_));
	$this->_constructor(@_) if ($this->can('_constructor'));
	return($this);
}

sub _constructor
#(<object>)
{ # compromise, this is the rule
	if(exists($_[P_VALUE])) {
		${$_[THIS]} = $_[P_VALUE];
	}
	return;
}

sub sibling_constructor
#(<object>, ...)
{
	my $class = ref(shift(@_));
	return($class->constructor(@_));
}

sub prototype_constructor
#(<class>)
{
	my $value = undef;
	return(bless(\$value, $_[P_CLASS]));
}

sub clone_constructor
#(<object>)
{
	my $value = ${$_[THIS]};
	return(bless(\$value, ref($_[THIS])));
}

#sub _lock
##(<object>)
#{ # no structure to lock
#}

1;
