#!/usr/bin/perl -w
# --
# otrs.AutoAllocation.pl - Clean the ticket archive flag
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: otrs.AutoAllocation.pl,v 1.3 2013/02/06 17:49:20 cr Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use vars qw($VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

#
# use required modules
#
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
$CommonObject{GroupObject}  = Kernel::System::Group->new(%CommonObject);
$CommonObject{SessionObject}	= Kernel::System::AuthSession->new(%CommonObject);
$CommonObject{AutoAllocation}	= Kernel::Modules::TicketAutoAssignment->new();


#
# declar variables
#
my $TicketSearchLimit;
my @TicketIDs;
my $MatchedUserRef;
my @TicketAssignedSummary	= ();
my @TicketAssignedFailSummary	= ();
my $ArticleType			= 'note-internal';
my $SenderType			= 'system';
my $Subject			= 'Owner Update';
my $Body			= 'Owner changed - Auto ticket assign';
my $CharSet			= 'ISO-8859-15';
my $MimeType			= 'text/plain';
my $HistoryType			= 'OwnerUpdate';
my $HistoryComment		= '%%Note';
my $UserID			= 1;
my $From			= 'Admin OTRS';

#
# get the required field from configuration item
#
$TicketSearchLimit = $CommonObject{ConfigObject}->{'Core::Ticket::AutoAssign'}->{ConfigurationItems}->{TicketSearchLimit};


# check no of ticket search limit is not exceed the upper bound
if( ($TicketSearchLimit eq '') || ( $TicketSearchLimit > 1000) ) {
	$TicketSearchLimit = 1000;
}

#
# get all tickets with an open statetype
#
@TicketIDs = $CommonObject{TicketObject}->TicketSearch(
	StateType	=> ['new'], 
	States		=> ['new'],
	Result		=> 'ARRAY',
	Limit		=> $TicketSearchLimit || 1000,
	UserID		=> 1,
	OwnerIDs	=> [1],
	Permission	=> 'ro',
);

if ( !@TicketIDs ) {
	$CommonObject{LogObject}->Log(
		Priority => 'notice',
		Message  => "No new ticket found to assign support desk agent.",
	);
	exit;
}

#
# get online users which is matched with given Group & Roles
#
$MatchedUserRef = &_GetOnlineAgent( \%CommonObject );

#
# check each ticket
#
foreach my $TicketID ( @TicketIDs ) {

	# declar variables
	my $SuitableAgentID;

	# get ticket details
	my %TicketDetails = $CommonObject{TicketObject}->TicketGet(
		TicketID => $TicketID,
		UserID   => 1,
	);

	# if on-line user matched with given role & Group get suitable agent. 
	if( ref $MatchedUserRef ne 'ARRAY' ) {
		$CommonObject{LogObject}->Log(
			Priority => 'notice',
			Message  => "on-line users is not matched with given Role/Group OR no on-line user is found.",
		);
	}
	if( ref $MatchedUserRef eq 'ARRAY' and scalar @{$MatchedUserRef} >= 1 ) {
		$SuitableAgentID = $CommonObject{AutoAllocation}->Run( UserIds => $MatchedUserRef, );
	}

	# if no suitable agent found throw a message
	if( !$SuitableAgentID ) {
		$CommonObject{LogObject}->Log(
			Priority => 'notice',
			Message  => "No suitable user found to assign ticket.",
		);
	}

	#Auto allocate the ticket if some suitable agent is identified
	if( $SuitableAgentID ) {

		my $SampleComment = "Ticket auto allocated using batch process.";
	     	
		#set ticket state to lock.
		$CommonObject{TicketObject}->TicketLockSet(
			TicketID => $TicketID,
			Lock     => 'lock',
			UserID   => 1,
		);

		#change ticket owner.
		my $Success = $CommonObject{TicketObject}->TicketOwnerSet(
				TicketID  => $TicketID,
				UserID    => 1,
				NewUserID => $SuitableAgentID,
				Comment   => $SampleComment,
			);

		# set ticket state to open
		$CommonObject{TicketObject}->TicketStateSet(
			State    => 'open',
			TicketID => $TicketID,
			UserID   => 1,
		);

		# article create
		$CommonObject{TicketObject}->ArticleCreate(
			TicketID	=> $TicketID,
			ArticleType	=> $ArticleType,
			SenderType	=> $SenderType,
			From		=> $From,
			Subject		=> $Subject,
			Body		=> $Body,
			Charset		=> $CharSet,
			MimeType	=> $MimeType,
			HistoryType	=> $HistoryType,
			HistoryComment	=> $HistoryComment,
			UserID		=> $UserID,
			%TicketDetails,
		);

		if ( $Success && $Success eq 1 ) {
			push @TicketAssignedSummary, $TicketDetails{TicketNumber};
		}
		else {
			push @TicketAssignedFailSummary, $TicketDetails{TicketNumber};
		}

	}
}

#
# ticket summary write in log
#
if( @TicketAssignedSummary && scalar @TicketAssignedSummary >=1 ) {
	my $TotalTicket = scalar @TicketAssignedSummary;
	$CommonObject{LogObject}->Log(
		Priority => 'notice',
		Message  => "Total no of tickets assigned=$TotalTicket",
	);
}
if( @TicketAssignedFailSummary && scalar @TicketAssignedFailSummary >=1 ) {
	my $TotalTicket = scalar @TicketAssignedFailSummary;
	$CommonObject{LogObject}->Log(
		Priority => 'notice',
		Message  => "Total no of tickets failed to assign=$TotalTicket",
	);
}

#----------------------------------------------------------
# Get online agent -- START
#-----------------------------------------------------------
sub _GetOnlineAgent {

	my $ObjectRef = $_[0];
	my %CommonObject = %{$ObjectRef};

	#
	# declare variables
	#
	my %Online = ();
	my @OnlineUsers;
	my @SutableOnlineUsers;
	my $MaxInactiveInterval;
	my $RoleList;
	my $GroupList;
	my @Roles;
	my @Groups;
	my @UserBelongsToGroup;
	my @UserBelongsToRole;
	my $SuitableAgent;

	#
	# get required fields
	#
	$MaxInactiveInterval	= $CommonObject{ConfigObject}->{'Core::Ticket::AutoAssign'}->{ConfigurationItems}->{MaxInactiveInterval};
	$RoleList		= $CommonObject{ConfigObject}->{'Core::Ticket::AutoAssign'}->{ConfigurationItems}->{RoleList};
	$GroupList		= $CommonObject{ConfigObject}->{'Core::Ticket::AutoAssign'}->{ConfigurationItems}->{GroupList};

	# clean rolelist & group list
	if( $RoleList ) {
		$RoleList =~ s/^\s*$//g;
		$RoleList =~ s/^\s*//g;
		$RoleList =~ s/\s*$//g;
		$RoleList =~ s/\s*,\s*/,/g;
	}
	if( $GroupList ) {
		$GroupList =~ s/^\s*$//g;
		$GroupList =~ s/^\s*//g;
		$GroupList =~ s/\s*$//g;
		$GroupList =~ s/\s*,\s*/,/g;
	}

	my ( $Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay ) = $CommonObject{TimeObject}->SystemTime2Date(
		SystemTime => $CommonObject{TimeObject}->SystemTime(),
	);
	
	my $CurrentTime = $CommonObject{TimeObject}->Date2SystemTime(
		Year   => $Year,
		Month  => $Month,
		Day    => $Day,
		Hour   => $Hour,
		Minute => $Min,
		Second => $Sec,
	);

	# if Group and Role list is not mentioned in config item
	if( ( !$GroupList) and ( !$RoleList ) ) {
		$CommonObject{LogObject}->Log(
			Priority => 'notice',
			Message  => "Group or Role list is not mentioned in config item.",
		);
		return;
	}

	# split roles and groups by ,
	if( $RoleList ) {
		@Roles = split(',',$RoleList);
	}
	if( $GroupList ) {
		@Groups = split(',',$GroupList);
	}

	# check and convert MaxInactiveInterval time into second
	if( $MaxInactiveInterval ) {
		# convert into seconds
		$MaxInactiveInterval = $MaxInactiveInterval * 60;
	}
	else {
		#set default value 15 Min.
		$MaxInactiveInterval = 900;
	}
	
	# check for online Agent
	my @Sessions = $CommonObject{SessionObject}->GetAllSessionIDs();
	for (@Sessions) {
		my %Data = $CommonObject{SessionObject}->GetSessionIDData( SessionID => $_, );

		if (($Data{UserType} eq 'User') && (($CurrentTime - $Data{UserLastRequest} ) < $MaxInactiveInterval ) ) {
			$Online{"UserLogin" }	= $Data{UserLogin};
			$Online{"lastRequest"}	= $Data{UserLastRequest};
			$Online{"userID"}	= $Data{UserID};
			$Online{"userEmail"}	= $Data{UserEmail};
			$Online{"userFirstname"}= $Data{UserFirstname};
			$Online{"userLastname"}	= $Data{UserLastname};

			push(@OnlineUsers,$Data{UserID});
		}
	}

	# when no user is online
	if ( !@OnlineUsers ) {
		$CommonObject{LogObject}->Log(
			Priority => 'notice',
			Message  => "No user is online.",
		);
		exit;
	}

	# check each online user and match with given roles & groups
	foreach my $OnlineUser (@OnlineUsers) {
		my $GroupSQLQuery;
		my $GroupUserSQLQuery;
		my $RoleSQLQuery;
		my $RoleUserSQLQuery;
		my $GroupID;
		my $RoleID;

		# check user is part of given groups
		foreach my $Group ( @Groups ) {
			$GroupID = $CommonObject{GroupObject}->GroupLookup( Group => $Group );
			
			my @Users = $CommonObject{GroupObject}->GroupMemberList(
					GroupID => $GroupID,
					Type   => 'rw',
					Result => 'ID',
				);
				
			foreach ( @Users ) {
				if ( $_ == $OnlineUser) {
					push @UserBelongsToGroup, $_;	
				}
			}
		}
		
		# check user is part of given roles
		foreach my $Role ( @Roles ) {
			$RoleID = $CommonObject{GroupObject}->RoleLookup( Role => $Role );

			my @Users = $CommonObject{GroupObject}->GroupUserRoleMemberList(
					RoleID => $RoleID,
					Result => 'ID',
				);
			
			foreach ( @Users ) {
				if ( $_ == $OnlineUser ) {
					push @UserBelongsToRole, $_;	
				}
			}
		}
	}

	# get the unique online user list from matched group list
	my %TempHash1;
	if( scalar @UserBelongsToGroup > 1 ) {
		@UserBelongsToGroup = grep { ! $TempHash1{ $_ }++ } @UserBelongsToGroup;
	}

	# get the unique online user list from matched role list
	my %TempHash2;
	if( scalar @UserBelongsToRole > 1 ) {
		@UserBelongsToRole = grep { ! $TempHash2{ $_ }++ } @UserBelongsToRole;
	}

	# when both group and Role is mentioned in config item
	if( ($GroupList and $GroupList ne "") and ($RoleList and $RoleList ne "") ) {

		# return matched users belongs to Group and Roles
		if( scalar @UserBelongsToGroup >= 1 && scalar @UserBelongsToRole >= 1  ) {

			# get common users from two list
			my @CommonUser = ();
			my %Count = map { $_ => 1 } @UserBelongsToGroup;
			@CommonUser = grep { $Count{$_} } @UserBelongsToRole;
			if( @CommonUser && scalar @CommonUser >= 1 ) {
				return \@CommonUser;
			}
			else {
				return;
			}
		}
		else {
			return;
		}
	}

	# when only group is mentioned in config item
	if( ($GroupList and $GroupList ne "") and (!$RoleList) ) {
		if ( scalar @UserBelongsToGroup >= 1 ) {
			return \@UserBelongsToGroup;
		}
		else {
			return;
		}
	}

	# when only role is mentioned in config item
	if( ($RoleList and $RoleList ne "") and (!$GroupList) ) {
		if ( scalar @UserBelongsToRole >= 1 ) {
			return \@UserBelongsToRole;
		}
		else {
			return;
		}
	}

	return ;
}
#----------------------------------------------------------
# Get online agent -- END
#-----------------------------------------------------------

