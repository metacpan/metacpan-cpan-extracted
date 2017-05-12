package RT::Action::CIFMinimal_SetStatus;

use strict;
use warnings;

use base 'RT::Action::Generic';

sub Prepare { return 1; }

sub Commit {
	my $self = shift;

	my $arg = $self->Argument();
	return undef unless($arg);

	$self->TicketObj->SetStatus($arg);
	return 1;
}

1;
