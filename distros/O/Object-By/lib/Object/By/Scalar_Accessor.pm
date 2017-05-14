package Object::By::Scalar_Accessor;

use 5.8.1;
use strict;
use warnings;

sub THIS() { 0 };

sub P_VALUE() { 1 }
sub value
#(<object>)
{
	return(${$_[THIS]});
};

sub copy_into_scalar
#(<object>, <value>)
{
	$_[P_VALUE] = ${$_[THIS]};
	return;
};

sub set
#(<object>, <value>)
{
	${$_[THIS]} = $_[P_VALUE];
	return;
};

sub clone_n_set
#(<object>, <value>)
{
	my $clone = $_[THIS]->clone_constructor;
	$$clone = $_[P_VALUE];
	return($clone);
};

sub set_if_undefined
#(<object>, <value>)
{
	return if (defined(${$_[THIS]}));
	${$_[THIS]} = $_[P_VALUE];
	return;
};

sub append
#(<object>, <value>)
{
	${$_[THIS]} .= $_[P_VALUE];
	return;
};

sub append_to_scalar
#(<object>, <value>)
{
	$_[P_VALUE] .= ${$_[THIS]};
	return;
}

sub clear
#(<object>)
{
	${$_[THIS]} = undef;
	return;
};

# note there is no "reset", because no room to store what "re" should be

sub length
#(<object>)
{
	return(length(${$_[THIS]}));
}

sub is_in_set
#(<object>, ...)
{
	my $this = shift(@_);
	return(grep($$this eq $_, @_));
}

1;
