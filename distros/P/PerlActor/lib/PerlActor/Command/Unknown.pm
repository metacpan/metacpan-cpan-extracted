package PerlActor::Command::Unknown;
use strict;

use base 'PerlActor::Command';

use PerlActor::Exception::CommandNotFound;

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	my $error = $self->getParam(0);
	throw PerlActor::Exception::CommandNotFound("unknown or invalid command: $error");
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
