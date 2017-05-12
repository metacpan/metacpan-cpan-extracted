#!/usr/bin/perl -w
# --
# otrs.Escalation.pl - Clean the ticket archive flag
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: otrs.Escalation.pl,v 1.0 2013/02/06 17:49:20 en Exp $
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

#use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);



use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Main;
use Kernel::System::Ticket;
use Kernel::System::Queue;
use Kernel::System::Group;
use Kernel::System::SLA;
use Kernel::System::Email;
use  Kernel::System::User;
use Kernel::System::Escalation;



# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-otrs.EscalationMatrix.pl',
    %CommonObject,
);
$CommonObject{MainObject}   = Kernel::System::Main->new(%CommonObject);
$CommonObject{TimeObject}   = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject}     = Kernel::System::DB->new(%CommonObject);
$CommonObject{TicketObject} = Kernel::System::Ticket->new(%CommonObject);
$CommonObject{QueueObject}  = Kernel::System::Queue->new(%CommonObject);
$CommonObject{GroupObject}  = Kernel::System::Group->new(%CommonObject);
$CommonObject{SLAObject}    = Kernel::System::SLA->new(%CommonObject);
$CommonObject{ESCLObject}   = Kernel::System::Escalation->new(%CommonObject);
$CommonObject{EmailObject}  = Kernel::System::Email->new(%CommonObject);
$CommonObject{UserObject}   = Kernel::System::User->new(%CommonObject);


# declar variable to hold escalation and role parameter
my %ESCLData;
my %Roles = $CommonObject{GroupObject}->RoleList( Valid => 1 );
my $RolesRef = \%Roles;
my %RoleAct;


#get ticket IDs. Filter needs to be modified. @TicketIDs is the list of IDs which will be checked.
my @TicketIDs = $CommonObject{TicketObject}->TicketSearch(
	Result          		 => 'ARRAY',
	SortBy          		 => 'Age',
	OrderBy         		 => 'Down',
	States   			 => ['new', 'open'],
	UserID          		 => 1,
	Limit           		 => 600,
);


foreach my $TID (@TicketIDs)
{
	#get ticket info.
	my %Ticket = $CommonObject{TicketObject}->TicketGet(
		TicketID => $TID,
	);

	#find ticket SLA type.
	my $ticketSLAID = $Ticket{SLAID};
	my $ticketGRPID = $Ticket{GroupID};
	my $TktOwner = $Ticket{OwnerID};
	my $TktNumber = $Ticket{TicketNumber};
	my $TktQueueID = $Ticket{QueueID};
	
	#################################   
	
      
	if ($ticketSLAID) 
	{
	    
	    # Define some global variable to initialised value from DB
	    
	    our $FR_NotifyTo_1;
	    our $FR_NotifyPerc_1;
	    our $FR_NotifyTo_2;
	    our $FR_NotifyPerc_2;
	    our $FR_NotifyTo_3;
	    our $FR_NotifyPerc_3;
	    
	    our $UT_NotifyTo_1;
	    our $UT_NotifyPerc_1;
	    our $UT_NotifyTo_2;
	    our $UT_NotifyPerc_2;
	    our $UT_NotifyTo_3;
	    our $UT_NotifyPerc_3;
	    
	    our $ST_NotifyTo_1;
	    our $ST_NotifyPerc_1;
	    our $ST_NotifyTo_2;
	    our $ST_NotifyPerc_2;
	    our $ST_NotifyTo_3;
	    our $ST_NotifyPerc_3;
	    
	    # declar variable to hold actual roleid related to the ticket
	    my %Roleid;
	    
	    ###############################################   
	    # get escalation matrix
	    ###############################################
	    %ESCLData = $CommonObject{ESCLObject}->ESCLGet(
	    SLAID  => $ticketSLAID,
	    UserID => 1,
	    );
	    
	    my @Typearray = qw(FR UT ST);
	    
	    foreach my $Type (@Typearray)
	    {
		# can increase level of escalation
		foreach my $Level (1..3)
		{
		 #my $Ref =  $Type . "_NotifyTo_" . $Level;
		 #my $RefPerc = $Type . "_NotifyPerc_" . $Level;
		 #$$Ref = $ESCLData{$ticketSLAID}{$Type}{$Level}{Notify_To};
		 #$$RefPerc = $ESCLData{$ticketSLAID}{$Type}{$Level}{Notify_Perc};
		 ${$Type . "_NotifyTo_" . $Level} = $ESCLData{$ticketSLAID}{$Type}{$Level}{Notify_To};
		 ${$Type . "_NotifyPerc_" . $Level} = $ESCLData{$ticketSLAID}{$Type}{$Level}{Notify_Perc};
		    
		}
	    }
	    
	    ##########################################################
	    #list of all users in a group associated with ticket-group
	    ##########################################################
	    my %GroupUser = $CommonObject{GroupObject}->GroupGroupMemberList( 
		GroupID => $ticketGRPID,
		Type    => 'move_into',
		Result  => 'HASH',
	    );
	    
	    #########################################
	    # finding role for each group user
	    #########################################
	        
	    foreach my $key (keys %GroupUser)
	    {
	    	my @UserRoleArray;
	        
	    	# get role ids in which the user is a member roleid=>userid
	    	   my %MemberRoleid = $CommonObject{GroupObject}->GroupUserRoleMemberList(
	    	    UserID => $key,
	    	    Result => 'HASH',
	    	);
	    	    if (%MemberRoleid) {
			foreach my $id (keys %MemberRoleid)
			{
			    push(@UserRoleArray,$id);
			}
			$Roleid{$key} = \@UserRoleArray;
		    }
	    }
		
	    ##############################################	
		
	    ##############################################	
	    # populate the mail list
	    ##############################################
		my @FR_NotifyMail_1;
		my @FR_NotifyMail_2;
		my @FR_NotifyMail_3;
		
		my @UT_NotifyMail_1;
		my @UT_NotifyMail_2;
		my @UT_NotifyMail_3;
		
		my @ST_NotifyMail_1;
		my @ST_NotifyMail_2;
		my @ST_NotifyMail_3;
		
		# for FR find the mail list
		#FR1
		@FR_NotifyMail_1 = _Getusrid($FR_NotifyTo_1);
		#FR2
		@FR_NotifyMail_2 = _Getusrid($FR_NotifyTo_2);
		push(@FR_NotifyMail_2, @FR_NotifyMail_1);
		@FR_NotifyMail_2 = _Unique(\@FR_NotifyMail_2);
		
		
		#FR3
		@FR_NotifyMail_3 = _Getusrid($FR_NotifyTo_3);
		push(@FR_NotifyMail_3, @FR_NotifyMail_2);
		@FR_NotifyMail_3 = _Unique(\@FR_NotifyMail_3);    
		
		# for UT find the mail list
		#UT1
		@UT_NotifyMail_1 = _Getusrid($UT_NotifyTo_1);
		#UT2
		@UT_NotifyMail_2 = _Getusrid($UT_NotifyTo_2);
		push(@UT_NotifyMail_2, @UT_NotifyMail_1);
		@UT_NotifyMail_2 = _Unique(\@UT_NotifyMail_2);
		#UT3
		@UT_NotifyMail_3 = _Getusrid($UT_NotifyTo_3);
		push(@UT_NotifyMail_3, @UT_NotifyMail_2);
		@UT_NotifyMail_3 = _Unique(\@UT_NotifyMail_3);
	        
		# for ST find the mail list
		#ST1
		@ST_NotifyMail_1 = _Getusrid($ST_NotifyTo_1);
		#ST2
		@ST_NotifyMail_2 = _Getusrid($ST_NotifyTo_2);
		push(@ST_NotifyMail_2, @ST_NotifyMail_1);
		@ST_NotifyMail_2 = _Unique(\@ST_NotifyMail_2);
		#ST3
		@ST_NotifyMail_3 = _Getusrid($ST_NotifyTo_3);
		push(@ST_NotifyMail_3, @ST_NotifyMail_2);
		@ST_NotifyMail_3 = _Unique(\@ST_NotifyMail_3);
	    ######################################################
	        
	    #####################################################
	    # find SLA details for a particulat ticket
	    #####################################################
	     my %SLAData = $CommonObject{SLAObject}->SLAGet(
		SLAID  => $ticketSLAID,
		UserID => 1,
		);
	    ###########################################
	    #percentage calculation of FR UT ST
	    ###########################################
		
		
		##########
		#FR
		##########
		    my $FirstRespTime = $SLAData{FirstResponseTime}; #in minutes
		    my $FirstRespRemaining = $Ticket{FirstResponseTime}; #in seconds
		    my $percentElapsedFR;
		if($FirstRespRemaining && $FirstRespTime){
		    #Calculate percent time elapsed
		    $percentElapsedFR = 100 - ((($FirstRespRemaining)/($FirstRespTime * 60))*100);
		}
		else{
		$percentElapsedFR = -1;
		} 
		
		if($FR_NotifyTo_1 && $FR_NotifyPerc_1) {
		    my $RoleName;
		    if($FR_NotifyTo_1 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$FR_NotifyTo_1};
		    }
		    if(($FR_NotifyPerc_1 <= $percentElapsedFR)&&($percentElapsedFR >= 0)){
			_SendNotification(\@FR_NotifyMail_1,$FR_NotifyPerc_1,$TID,'First Response -Level1',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedFR,'FRNotify1',$TktQueueID);  
		    }  
		}
		
		##FR2
	    	if($FR_NotifyTo_2 && $FR_NotifyPerc_2) {
		    my $RoleName;
		    if($FR_NotifyTo_2 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$FR_NotifyTo_2};
		    }
		    if(($FR_NotifyPerc_2 <= $percentElapsedFR)&&($percentElapsedFR >= 0)){
			  
			_SendNotification(\@FR_NotifyMail_2,$FR_NotifyPerc_2,$TID,'First Response -Level2',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedFR,'FRNotify2',$TktQueueID);  
		       
		    }  
		}
		
		##FR3
	    	if($FR_NotifyTo_3 && $FR_NotifyPerc_3) {
		    my $RoleName;
		    if($FR_NotifyTo_3 == -99)
		    {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$FR_NotifyTo_3};
		    }
		    if(($FR_NotifyPerc_3 <= $percentElapsedFR)&&($percentElapsedFR >= 0)){
			  
			  
			_SendNotification(\@FR_NotifyMail_3,$FR_NotifyPerc_3,$TID,'First Response -Level3',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedFR,'FRNotify3',$TktQueueID);  
		       
		    }  
		}
		
		##########
		#UT
		##########
		
		my $UpdateTime = $SLAData{UpdateTime}; #in minutes
		my $UpdateRemaining = $Ticket{UpdateTime}; #in seconds
		my $percentElapsedUT;
		if($UpdateRemaining && $UpdateTime) {
		    #Calculate percent time elapsed
		    $percentElapsedUT = 100 - ((($UpdateRemaining)/($UpdateTime * 60))*100);
		    
		    
		}
		else {
		    $percentElapsedUT = -1;
		} 
		
		##UT1
		
		if($UT_NotifyTo_1 && $UT_NotifyPerc_1) {
		    my $RoleName;
		    if($UT_NotifyTo_1 == -99)
		    {
			$RoleName = 'owner';
		    }
		    else
		    {
			$RoleName = $Roles{$UT_NotifyTo_1};
		    }
		    if(($UT_NotifyPerc_1 <= $percentElapsedUT)&&($percentElapsedUT >= 0)){
			_SendNotification(\@UT_NotifyMail_1,$UT_NotifyPerc_1,$TID,'Update Time -Level1',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedUT,'UTNotify1',$TktQueueID);  
		       
		    }  
		}
		
		##UT2
	    	if($UT_NotifyTo_2 && $UT_NotifyPerc_2) {
		    my $RoleName;
		    if($UT_NotifyTo_2 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$UT_NotifyTo_2};
		    }
		    if(($UT_NotifyPerc_2 <= $percentElapsedUT)&&($percentElapsedUT >= 0)){
		          
		        _SendNotification(\@UT_NotifyMail_2,$UT_NotifyPerc_2,$TID,'Update Time -Level2',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedUT,'UTNotify2',$TktQueueID);  
		       
		    }  
		}
		
		##UT3
	    	if($UT_NotifyTo_3 && $UT_NotifyPerc_3) {
		    my $RoleName;
		    if($UT_NotifyTo_3 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$UT_NotifyTo_3};
		    }
		    if(($UT_NotifyPerc_3 <= $percentElapsedUT)&&($percentElapsedUT >= 0)){
			
			_SendNotification(\@UT_NotifyMail_3,$UT_NotifyPerc_3,$TID,'Update Time -Level3',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedUT,'UTNotify3',$TktQueueID);  
		       
		    }  
		}
		
		##########
		#ST
		##########
		
		    my $SolutionTime = $SLAData{SolutionTime}; #in minutes
		    my $SolutionRemaining = $Ticket{SolutionTime}; #in seconds
		    my $percentElapsedST;
		if($SolutionRemaining && $SolutionTime){
		    #Calculate percent time elapsed
		    $percentElapsedST = 100 - ((($SolutionRemaining)/($SolutionTime * 60))*100);
		    
		
		}
		else {
		    $percentElapsedST = -1;
		} 
		
		##ST1
		if($ST_NotifyTo_1 && $ST_NotifyPerc_1) {
		    my $RoleName;
		    if($ST_NotifyTo_1 == -99)
		    {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$ST_NotifyTo_1};
		    }
		    if(($ST_NotifyPerc_1 <= $percentElapsedST)&&($percentElapsedST >= 0)){
			_SendNotification(\@ST_NotifyMail_1,$ST_NotifyPerc_1,$TID,'Solution Time -Level1',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedST,'STNotify1',$TktQueueID);  
		       
		    }  
		}
		
		##ST2
	    	if($ST_NotifyTo_2 && $ST_NotifyPerc_2) {
		    my $RoleName;
		    if($ST_NotifyTo_2 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$ST_NotifyTo_2};
		    }
		    if(($ST_NotifyPerc_2 <= $percentElapsedST)&&($percentElapsedST >= 0)){
			  
			_SendNotification(\@ST_NotifyMail_2,$ST_NotifyPerc_2,$TID,'Solution Time -Level2',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedST,'STNotify2',$TktQueueID);  
		       
		    }  
		}
		
		##ST3
	    	if($ST_NotifyTo_3 && $ST_NotifyPerc_3) {
		    my $RoleName;
		    if($ST_NotifyTo_3 == -99) {
			$RoleName = 'owner';
		    }
		    else {
			$RoleName = $Roles{$ST_NotifyTo_3};
		    }
		    if(($ST_NotifyPerc_3 <= $percentElapsedST)&&($percentElapsedST >= 0)){
			 
			 
			_SendNotification(\@ST_NotifyMail_3,$ST_NotifyPerc_3,$TID,'Solution Time -Level3',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedST,'STNotify3',$TktQueueID);  
		       
		    }  
		}
		
	    	
		
	#############################################################	
	    
	    
	    $FR_NotifyTo_1 = '';
	    $FR_NotifyPerc_1 = '';
	    $FR_NotifyTo_2 = '';
	    $FR_NotifyPerc_2 = '';
	    $FR_NotifyTo_3 = '';
	    $FR_NotifyPerc_3 = '';
	    $UT_NotifyTo_1 = '';
	    $UT_NotifyPerc_1 = '';
	    $UT_NotifyTo_2 = '';
	    $UT_NotifyPerc_2 = '';
	    $UT_NotifyTo_3 = '';
	    $UT_NotifyPerc_3 = '';
	    $ST_NotifyTo_1 = '';
	    $ST_NotifyPerc_1 = '';
	    $ST_NotifyTo_2 = '';
	    $ST_NotifyPerc_2 = '';
	    $ST_NotifyTo_3 = '';
	    $ST_NotifyPerc_3 = '';
	    
	    
	#########################################
	
	    sub _Unique{
		
		#(@{$destArray})
		my $Temparray = $_[0];
		my @UniqueArray = ();
		my %TempHash = ();
		
		foreach my $Key (@{$Temparray}) {
		    if ($Key) {
			$TempHash{$Key} = 1;
		    }	
		    
		}
		
		@UniqueArray = keys %TempHash;
		
		return (@UniqueArray);
		
	    }
	
	    sub _Getusrid{
	        
	        my $NotifyTo =$_[0];
	        my @NotifyMail;
	        if($NotifyTo) {
		    if($NotifyTo == -99) {
			push (@NotifyMail,$Ticket{OwnerID});
			return (@NotifyMail);
		    }
		    else {
		        foreach my $uid (keys %Roleid)
		        {
			    
			    my $TempArrayAddress = \$Roleid{$uid};
			    
			    foreach my $rid (@$$TempArrayAddress) {
			       if($NotifyTo == $rid) {
				  push(@NotifyMail,$uid);
				}
			    }
			}
			return (@NotifyMail);  
		    }
		} 
	    }	
	#############################################  
	    
	} ## End of if ($ticketSLAID)
	
    }  ## End of foreach my $TID (@TicketIDs)



sub _SendNotification{
	
	##_SendNotification(\@FR_NotifyMail_1,$FR_NotifyPerc_3,$TID,'First Response -Level3',$ticketSLAID,$RoleName,$TktOwner,$TktNumber,$percentElapsedFR, 'FRNotify3',$TktQueueID);  
	
	# declear and initialised variable
	
	my $destArray = $_[0];
	my $Percent   = $_[1] || '';
	my $TicketID  = $_[2] || '';
	my $EscType   = $_[3] || '';
	my $SLAID     = $_[4] || '';
	my $level     =	$_[5] || '';
	my $TktOwner  = $_[6] || '';
	my $TktNumber = $_[7] || '';
	my $ActualPerc = $_[8] || '';
	my $UKey       = $_[9] || '';
	my $TktQueueID = $_[10] || '';
	
	
	my %TicketOwnerData = $CommonObject{UserObject}->GetUserData(
               UserID => $TktOwner,
               Valid  => 1,
        );
	
	#[Ticket#2012101110000044] Ticket Escalation Before! (10% of First Response - Level1)
	
	my $UniqueName = $TicketID . "-" . $SLAID .  "-" . $UKey . "-" . $level;
	my $Subject = "[Ticket#" . $TktNumber . "] Ticket Escalation Before! (" . $Percent . " % of " . $EscType . ")";
	my $Body = "Ticket " . $TktNumber . " has breached " . $Percent . " % of " . $EscType . "\n";
	$Body = $Body . "Ellapsed Percentage is : " . $ActualPerc . "\n";
	$Body = $Body . "Ticket Owner ID : " . $TicketOwnerData{UserEmail} . "\n";
	$Body = $Body . "SLA : " . $SLAID . "\n";
	$Body = $Body . "\n \n";
	$Body = $Body . "Regards \n";
	$Body = $Body . "OTRS Admin \n";
	$Body = $Body . "\n\nPlease Note:" . "\n" . "FR: First Response\n" . "UT: Update Time\n". "ST: Solution Time\n";
	my $Msg = $Percent . " % of " . $EscType ;
	
	
	my @Lines = $CommonObject{TicketObject}->HistoryGet(
    		TicketID => $TicketID,
   		UserID   => 1,
	);
        my $Sent = 1;

	

	for my $Line (@Lines) 
	{
		#if ($Line->{Name} =~ /\%\%$UniqueName\%\%/ )
	       if ($Line->{Name} eq $UniqueName)
		{
		    $Sent = 0;
		}
	}	 
        
	
	#$Sent = 1;
	
        if($Sent)
        {
		my $Queue = $CommonObject{QueueObject}->QueueLookup( QueueID => $TktQueueID );
		
		$CommonObject{TicketObject}->HistoryAdd(
				TicketID     => $TicketID,
				CreateUserID => 1,
				HistoryType  => 'Misc',
				Name         => $UniqueName,
			);
		
        	foreach my $Recipient (@{$destArray}) {
			
			
			my $Result = $CommonObject{TicketObject}->SendAgentNotification(
			    TicketID              => $TicketID,
			    CustomerMessageParams => {
                            Queue => $Queue,
                            Body => $Msg || '',
	 	            },
			    Type                  => 'EscalationMatrix',
			    RecipientID           => $Recipient,
			    UserID                => 1,
			);
		       
			
			#if ($Result) {
			#    open(FF,">>/tmp/tick.txt");
			#    print FF "\n sent -> $recipient, $UserData{UserEmail}, $Subject ---- \n";
			#    close(FF);
			#    print "Email sent! ->  $recipient, $UserData{UserEmail}, $Subject ----\n";
			#}
			#else {
			#    print "Email not sent!\n";
			#}
		}
	}
	$Sent = 1;
	
}
