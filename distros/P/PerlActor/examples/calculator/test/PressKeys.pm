package PressKeys;
use strict;

use base 'PerlActor::Command';

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	my @keys = $self->getParams();
	foreach my $key (@keys)
	{
		$self->getContext()->{calculator}->pressKey($key);
	}
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
