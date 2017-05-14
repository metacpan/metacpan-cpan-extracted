package Object::By::Typeglob;

use strict;
use warnings;
use Symbol;

sub THIS() { 0 }

sub P_CLASS() { 0 }
sub P_VALUE() { 1 }
sub constructor
#(<class>)
{
	my $this = bless(\(Symbol::geniosym), shift(@_));
	$this->_constructor if ($this->can('_constructor'));
	return($this);
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
	return(bless(\(Symbol::geniosym), $_[P_CLASS]));
}

1;
