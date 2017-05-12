package PerlActor::Command::BornToFail;
use strict;

use base 'PerlActor::Command';

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	$self->assert(undef, 'born to fail');
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
