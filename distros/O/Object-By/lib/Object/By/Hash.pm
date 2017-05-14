package Object::By::Hash;

use 5.8.1;
use strict;
use warnings;

sub THIS() { 0 }

sub constructor
#(<class>, ...)
{
	my $this = bless({}, shift(@_));
	$this->_constructor(@_) if ($this->can('_constructor'));
	$this->_lock_object;

	return($this);
}

sub sibling_constructor
#(<object>, ...)
{
	my $class = ref(shift(@_));
	return($class->constructor(@_));
}

sub P_CLASS() { 0 }
sub prototype_constructor
#(<class>)
{
	return(bless({}, ref($_[P_CLASS])));
}


sub clone_constructor
#(<class>)
{
	my $cloned = {%{$_[THIS]}};
	bless($cloned, ref($_[THIS]));
	$cloned->_lock_object;

	return($cloned);
}

sub destructor
#(<class>, ...)
{ # structure of object
	my $this = $_[THIS];

	$this->_destructor(@_) if ($this->can('_destructor'));
	$this->_unlock_object;
	%$this = ();
	$this->_lock_object;
	return;
}

sub _lock_object
#(<object>)
{ # locks the structure (set of existing keys)
	Internals::hv_clear_placeholders(%{$_[THIS]});
	Internals::SvREADONLY(%{$_[THIS]}, 1);
	return;
}

sub _unlock_object
#(<object>)
{
	Internals::SvREADONLY(%{$_[THIS]}, 0);
	return;
}

# Could be used against memory leaks
#sub DESTROY
##(<object>)
#{
#	my $this = $_[THIS];
#
#	if (keys(%$this) > 0) {
#		$this->destructor if ($this->can('_destructor'));
#	}
#	return;
#}

1;
