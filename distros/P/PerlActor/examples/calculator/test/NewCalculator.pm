package NewCalculator;
use strict;

use base 'PerlActor::Command';
use Calculator;

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	$self->getContext()->{calculator} = new Calculator();
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
