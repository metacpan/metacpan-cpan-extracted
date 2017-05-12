package CheckDisplayReads;
use strict;

use base 'PerlActor::Command';

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	my $expected = $self->getParam(0);
	my $displayReads = $self->getContext()->{calculator}->getDisplay();
	$self->assert( $displayReads eq $expected, "Display is wrong: expected $expected, got $displayReads")
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
