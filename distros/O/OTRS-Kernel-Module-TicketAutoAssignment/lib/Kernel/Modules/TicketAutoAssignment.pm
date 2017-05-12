# --
# Kernel/Modules/TicketAutoAssignment.pm - all ticket functions
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: TicketAutoAssignment.pm,v 1.0.0.1 2011/02/05 00:05:20 en Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::TicketAutoAssignment;

use strict; 
use warnings;

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Main;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Ticket;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.28 $) [1]; 

sub new {
	my ( $Type, %Param ) = @_;

	# allocate new hash for object
	my $Self = {%Param};
	bless( $Self, $Type );

	# create common objects
	$Self->{ConfigObject}	= Kernel::Config->new();
	$Self->{LogObject}	= Kernel::System::Log->new(
					LogPrefix => 'OTRS-otrs.TicketAutoAllocation.pl',
					%{$Self},
				);
	$Self->{EncodeObject}	= Kernel::System::Encode->new(%{$Self});
	$Self->{MainObject}	= Kernel::System::Main->new(%{$Self});
	$Self->{TimeObject}	= Kernel::System::Time->new(%{$Self});
	$Self->{DBObject}		= Kernel::System::DB->new(%{$Self});
	$Self->{TicketObject}	= Kernel::System::Ticket->new(%{$Self});


	# check all needed objects
	for (qw(DBObject TicketObject ConfigObject LogObject)) {
		if ( !$Self->{$_} ) {
			die "Got no $_!\n";
		}
	}

	return $Self;
}


sub Run {
	my ( $Self, %Param ) = @_;

	# declar variables and get passed arguments
	my %TotalTickets = ();
	my $SutableAgent;
	my @Users;
	my $OnlineAgents = $Param{UserIds};

	# get matched users
	if(ref $OnlineAgents eq 'ARRAY' ) {
		@Users = @{$OnlineAgents};
	}

	# get current time
	my ($Sec, $Min, $Hour, $Day, $Month, $Year) = $Self->{TimeObject}->SystemTime2Date(
				SystemTime => $Self->{TimeObject}->SystemTime()-1*86400
			);
	my $LastDay = sprintf( "%04d-%02d-%02d",$Year,$Month,$Day);

	($Sec, $Min, $Hour, $Day, $Month, $Year) = $Self->{TimeObject}->SystemTime2Date(
				SystemTime => $Self->{TimeObject}->SystemTime()
			);

	my $CurDay = sprintf( "%04d-%02d-%02d",$Year,$Month,$Day);

	if( !@Users ) {
		 $Self->{LogObject}->Log(
			Priority => 'notice',
			Message  => "No suitable Agent found.",
		);
	}

	my %TicketSearchSummary = (
		CurClosedTickets => {
				StateType => [ 'closed', ],
				TicketCloseTimeNewerDate => $CurDay.' 00:00:00',
				},
		CurOpenTickets => {
				StateType => [ 'open', 'new' ],
				},
	);

	# for each user get total ticket count
	foreach my $user ( @Users ) {
		foreach my $type (keys %TicketSearchSummary) {
			my @TotalTicket = $Self->{TicketObject}->TicketSearch(
						Result => 'ARRAY',
						%{ $TicketSearchSummary{ $type } },
						UserID => '1',
						OwnerIDs => [ "$user"],
					);

			$TotalTickets{"$user"}{"$type"} = scalar @TotalTicket;
		}
		$TotalTickets{"$user"}{'TotalTickets'} = $TotalTickets{"$user"}{'CurClosedTickets'} + $TotalTickets{"$user"}{'CurOpenTickets'}; 
	}

	## get userid having lowest tickets
	## sort above builded hash by value
	foreach (sort { ($TotalTickets{$a}{'TotalTickets'} <=> $TotalTickets{$b}{'TotalTickets'}) } keys %TotalTickets ) { 
		$SutableAgent = $_;
		last ;
	}

	return $SutableAgent;
}

1;

__END__

=pod

=head2 NAME

Kernel::Modules::TicketAutoAssignment - interface lib

=head2 VERSION

$Revision: 1.0 $ $Date: 2013/02/04 14:38:57 $
$VERSION = qw($Revision: 1.0 $) [1];

=head2 Dependencies

No such extra dependency, general OTRS 3.1.x will do.

=head2 DESCRIPTION

This module is a interface module and will be access from interface OTRS interface and pl file.
User can download the module and keep it under Kernel/Modules/TicketAutoAssignment.pm or can get the opm file
from var/packagesetup/TicketAutoAssignment-1.0.1 and get installed as bundel in OTRS.

=head2 SYNOPSIS

All function for auto allocation of ticket when newly created.

=head1 PUBLIC INTERFACE

create an object

	use Kernel::Config;
	use Kernel::System::Encode;
	use Kernel::System::Log;
	use Kernel::System::Main;
	use Kernel::System::DB;
	use Kernel::System::Time;
	use Kernel::System::Ticket;
	use Kernel::System::AuthSession;
	use Kernel::Modules::TicketAutoAssignment;

	#
	# create common objects
	#
	my %CommonObject = ();
	$CommonObject{ConfigObject}	= Kernel::Config->new();
	$CommonObject{EncodeObject}	= Kernel::System::Encode->new(%CommonObject);
	$CommonObject{LogObject}	= Kernel::System::Log->new(
					LogPrefix => 'OTRS-otrs.AutoAllocation.pl',
					%CommonObject,
					);
	$CommonObject{MainObject}	= Kernel::System::Main->new(%CommonObject);
	$CommonObject{TimeObject}	= Kernel::System::Time->new(%CommonObject);
	$CommonObject{DBObject}		= Kernel::System::DB->new(%CommonObject);
	$CommonObject{TicketObject}	= Kernel::System::Ticket->new(%CommonObject);
	$CommonObject{GroupObject}  	= Kernel::System::Group->new(%CommonObject);
	$CommonObject{SessionObject}	= Kernel::System::AuthSession->new(%CommonObject);
	$CommonObject{AutoAllocation}	= Kernel::Modules::TicketAutoAssignment->new();



=head2 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).
This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.


=cut
