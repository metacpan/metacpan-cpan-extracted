package Object::By::Existing_Reference;

use 5.8.1;
use strict;
use warnings;

sub THIS() { 0 }

sub P_CLASS() { 0 }
sub P_VALUE_REF() { 1 }
sub constructor
#(<class> [, <value_ref>], ...)
{
	my ($class, $value_ref) = splice(@_, 0, 2);
	my $this = bless($value_ref, $class);
	$this->_constructor(@_) if ($this->can('_constructor'));
	$this->_lock_object if ($this->can('_lock_object'));
	return($this);
}

1;
