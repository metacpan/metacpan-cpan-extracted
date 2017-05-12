package PerlActor::Command::Dummy;
use strict;

use base 'PerlActor::Command';

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	$self->getContext()->{dummy_was_here} = 1;
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
