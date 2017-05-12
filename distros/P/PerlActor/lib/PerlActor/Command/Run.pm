package PerlActor::Command::Run;
use strict;

use base 'PerlActor::Command';

use PerlActor::Exception;

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;
	my $file = $self->getParam(0);
	$self->executeScript($file);
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
