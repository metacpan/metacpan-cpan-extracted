# --
# Kernel/Modules/AdminESCL.pm - admin frontend to manage slas
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: AdminESCL.pm,v 1.0 2013/02/04 14:38:57 en Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminESCL;

use strict;
use warnings;

use Kernel::System::Service;
use Kernel::System::SLA;
use Kernel::System::Escalation;
use Kernel::System::Valid;

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::Group;


# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-otrs.AdminESCL.pl',
    %CommonObject,
);
$CommonObject{MainObject}   = Kernel::System::Main->new(%CommonObject);
$CommonObject{DBObject}     = Kernel::System::DB->new(%CommonObject);
$CommonObject{GroupObject}  = Kernel::System::Group->new(%CommonObject);



use vars qw($VERSION);
$VERSION = qw($Revision: 1.0 $) [1];

sub new {
	my ( $Type, %Param ) = @_;
	
	# allocate new hash for object
	my $Self = {%Param};
	bless( $Self, $Type );
	
	# check all needed objects
	for (qw(ParamObject DBObject LayoutObject ConfigObject LogObject)) {
	    if ( !$Self->{$_} ) {
	        $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
	    }
	}
	#add some new object
	$Self->{ServiceObject} = Kernel::System::Service->new(%Param);
	$Self->{SLAObject}     = Kernel::System::SLA->new(%Param);
	$Self->{ESCLObject}     = Kernel::System::Escalation->new(%Param);
	$Self->{ValidObject}   = Kernel::System::Valid->new(%Param);
	
    return $Self;
}

sub Run {
	my ( $Self, %Param ) = @_;
	
	my %Error = ();
	
	# ------------------------------------------------------------ #
	# escl edit
	# ------------------------------------------------------------ #
	if ( $Self->{Subaction} eq 'ESCLEdit' ) {
	    
	    # header
	    my $Output = $Self->{LayoutObject}->Header();
	    $Output .= $Self->{LayoutObject}->NavigationBar();
	    
	    # html output
	        $Output .= $Self->_MaskNew(
	        %Param,
	        );
	    $Output .= $Self->{LayoutObject}->Footer();
	    
        return $Output;
	}
	
	# ------------------------------------------------------------ #
	# escl save
	# ------------------------------------------------------------ #
	elsif ( $Self->{Subaction} eq 'ESCLSave' ) {
	
	    # challenge token check for write action
	    $Self->{LayoutObject}->ChallengeTokenCheck();
	    
	    # get params
	    my %GetPerc;
	    my %GetParam;
		#get Param details
	        for my $Param (
  		    #qw(SLAID Name Calendar FirstResponseTime FirstResponseNotify SolutionTime SolutionNotify UpdateTime UpdateNotify ValidID Comment)
		    qw(SLAID Name Calendar FirstResponseTime FirstResponseNotify SolutionTime SolutionNotify UpdateTime UpdateNotify ValidID Comment TypeID MinTimeBetweenIncidents)
		    ) {
		    $GetParam{$Param} = $Self->{ParamObject}->GetParam( Param => $Param ) || '';
		}
		    
		#get Percentage details   
		for my $ParamEscl (
	               qw(SLAID Name FirstResponseRole1 FirstResponseNotify1 FirstResponseRole2 FirstResponseNotify2 FirstResponseRole3 FirstResponseNotify3 UpdateRole1 UpdateNotify1 UpdateRole2 UpdateNotify2 UpdateRole3 UpdateNotify3 SolutionRole1 SolutionNotify1 SolutionRole2 SolutionNotify2 SolutionRole3 SolutionNotify3)
			) {
	            $GetPerc{$ParamEscl} = $Self->{ParamObject}->GetParam( Param => $ParamEscl ) || '';
		}
		
	    	    
	    
	    # check needed stuff
	    %Error = ();
	    if ( !$GetParam{Name} ) {
	        $Error{'NameInvalid'} = 'ServerError';
	    }
	    
	    #open(FF,">>/tmp/escalation.txt");  
	    
	    # if no errors occurred
	    if ( !%Error ) {
		
	        # get service ids
	        my @ServiceIDs = $Self->{ParamObject}->GetArray( Param => 'ServiceIDs' );
	        $GetParam{ServiceIDs} = \@ServiceIDs;
		
	        # save to database
	        if ( !$GetParam{SLAID} ) {
		    
		    #if ( !$GetParam{SLAID} ) {
		            $Error{Message} = $Self->{LogObject}->GetLogEntry(
		            Type => 'Error',
		            What => 'Message',
		        );
		    #}
		}
		#start of main else part
		else {
		    
		    my $Success;
		    my $valid_id;
		     
		    # update for different stage i.e FirstResponse(FR), UpdateTime(UT), SolutionTime(ST)
		    ##FR 
			##LEVEL 1
			$Success = 1;
			$valid_id = 0;
			    
			    if ($GetPerc{FirstResponseRole1}) {
			        
			        if ($GetPerc{FirstResponseNotify1}) {
			    	$valid_id = 1;
			        }
			        else {
			    	$GetPerc{FirstResponseRole1} = '';
			    	$GetPerc{FirstResponseNotify1} = '';
			    	$valid_id = 2;
			        }
			    }
			    else {
			        $GetPerc{FirstResponseRole1} = '';
			        $GetPerc{FirstResponseNotify1} = '';
			        $valid_id = 2;
			    }
			    
			    undef $Success;
			    $Success =$Self->{ESCLObject}->ESCLAdd(
			        SLAID => $GetPerc{SLAID},
			        Level => 1,
			        Type => 'FR',
			        ValidID => $valid_id,
				Notify_To => $GetPerc{FirstResponseRole1},
				Notify_Perc => $GetPerc{FirstResponseNotify1},
				
			    );
			    
			    if ( !$Success ) {
			        $Error{Message} = $Self->{LogObject}->GetLogEntry(
			        Type => 'Error',
			        What => 'Message',
			        );
			        $Success = 1; 
			    }
		    
			##LEVEL 2
			$Success = 1;
			$valid_id = 0;
			if ($GetPerc{FirstResponseRole2}) {
			    
			    if ($GetPerc{FirstResponseNotify2}) {
			        $valid_id = 1;
			    }
			    else {
			    $GetPerc{FirstResponseRole2} = '';
			    $GetPerc{FirstResponseNotify2} = '';
			    $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{FirstResponseRole2} = '';
			    $GetPerc{FirstResponseNotify2} = '';
			    $valid_id = 2;
			}
			
			undef $Success;
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 2,
			    Type => 'FR',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{FirstResponseRole2},
			    Notify_Perc => $GetPerc{FirstResponseNotify2},
			    
			);
		    
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
			    $Success = 1; 
		        }
		
			##Level 3
			$Success = 1;
			$valid_id = 0;
			if ($GetPerc{FirstResponseRole3}) {
			    
			    if ($GetPerc{FirstResponseNotify3}) {
			    $valid_id = 1;
			    }
			    else {
			        $GetPerc{FirstResponseRole3} = '';
			        $GetPerc{FirstResponseNotify3} = '';
			        $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{FirstResponseRole3} = '';
			    $GetPerc{FirstResponseNotify3} = '';
			    $valid_id = 2;
			}
			
			undef $Success;
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 3,
			    Type => 'FR',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{FirstResponseRole3},
			    Notify_Perc => $GetPerc{FirstResponseNotify3},
			    
			);
			
		        if ( !$Success ) {
		            $Error{Message} = $Self->{LogObject}->GetLogEntry(
		            Type => 'Error',
		            What => 'Message',
		            );
		           $Success = 1; 
			}
		
		    ##UT
		        ##LEVEL 1
		        $Success = 1;
		        $valid_id = 0;
		        if ($GetPerc{UpdateRole1}) {
		        	
		            if ($GetPerc{UpdateNotify1}) {
				$valid_id = 1;
		            }    
		    	    else {
			        $GetPerc{UpdateRole1} = '';
			        $GetPerc{UpdateNotify1} = '';
			        $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{UpdateRole1} = '';
			    $GetPerc{UpdateNotify1} = '';
			    $valid_id = 2;
			}
			
		    	undef $Success;
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 1,
			    Type => 'UT',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{UpdateRole1},
			    Notify_Perc => $GetPerc{UpdateNotify1},
			    
			);
		    
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
			    $Success = 1; 
			}
		    
			##LEVEL 2
			$Success = 1;
			$valid_id = 0;
			if ($GetPerc{UpdateRole2}) {
			    
			    if ($GetPerc{UpdateNotify2}) {
			        $valid_id = 1;
			    }
			    else {
			        $GetPerc{UpdateRole2} = '';
			        $GetPerc{UpdateNotify2} = '';
			        $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{UpdateRole2} = '';
			    $GetPerc{UpdateNotify2} = '';
			    $valid_id = 2;
			}
			
			undef $Success;
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 2,
			    Type => 'UT',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{UpdateRole2},
			    Notify_Perc => $GetPerc{UpdateNotify2},
			    
			);
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
			   $Success = 1; 
			}
		    
			##LEVEL 3
			$Success = 1;
			$valid_id = 0;
			if ($GetPerc{UpdateRole3}) {
			    
			    if ($GetPerc{UpdateNotify3}) {
			        $valid_id = 1;
			    }
			    else
			    {
			        $GetPerc{UpdateRole3} = '';
			        $GetPerc{UpdateNotify3} = '';
			        $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{UpdateRole3} = '';
			    $GetPerc{UpdateNotify3} = '';
			    $valid_id = 2;
			}
			
			$Success = "";
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 3,
			    Type => 'UT',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{UpdateRole3},
			    Notify_Perc => $GetPerc{UpdateNotify3},
			    
			);
			
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
		            $Success = 1; 
		        }
	    
		    ##ST
		    ##LEVEL 1
		        $Success = 1;
		        $valid_id = 0;
		        if ($GetPerc{SolutionRole1}) {
		    	    
		            if ($GetPerc{SolutionNotify1}) {
		        	$valid_id = 1;
		            }
			    else {
			            $GetPerc{SolutionRole1} = '';
			            $GetPerc{SolutionNotify1} = '';
			            $valid_id = 2;
			    }
			}
		        else
		        {
		            $GetPerc{SolutionRole1} = '';
		            $GetPerc{SolutionNotify1} = '';
		            $valid_id = 2;
		        }
		        
		        undef $Success;
		        $Success =$Self->{ESCLObject}->ESCLAdd(
		            SLAID => $GetPerc{SLAID},
		            Level => 1,
		            Type => 'ST',
		            ValidID => $valid_id,
		            Notify_To => $GetPerc{SolutionRole1},
		            Notify_Perc => $GetPerc{SolutionNotify1},
		            
		        );
		    
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
			    $Success = 1; 
			}
		
		    ##LEVEL 2
			$Success = 1;
			$valid_id = 0;
			if ($GetPerc{SolutionRole2}) {
			    
			    if ($GetPerc{SolutionNotify2}) {
			        $valid_id = 1;
			    }
			    else
			    {
			        $GetPerc{SolutionRole2} = '';
			        $GetPerc{SolutionNotify2} = '';
			        $valid_id = 2;
			    }
			}
			else {
			    $GetPerc{SolutionRole2} = '';
			    $GetPerc{SolutionNotify2} = '';
			    $valid_id = 2;
			}
			
			undef $Success;
			$Success =$Self->{ESCLObject}->ESCLAdd(
			    SLAID => $GetPerc{SLAID},
			    Level => 2,
			    Type => 'ST',
			    ValidID => $valid_id,
			    Notify_To => $GetPerc{SolutionRole2},
			    Notify_Perc => $GetPerc{SolutionNotify2},
			    
			);
		
			if ( !$Success ) {
			    $Error{Message} = $Self->{LogObject}->GetLogEntry(
			    Type => 'Error',
			    What => 'Message',
			    );
			    $Success = 1; 
			}
		
		    ##LEVEL 3
			$Success = 1;
			$valid_id = 0;
			    if ($GetPerc{SolutionRole3}) {
			        
			        if ($GetPerc{SolutionNotify3}) {
			            $valid_id = 1;
			        }
			        else {
			            
			            $GetPerc{SolutionRole3} = '';
			            $GetPerc{SolutionNotify3} = '';
			            $valid_id = 2;
			        }
			    }
			    else {
			        $GetPerc{SolutionRole3} = '';
			        $GetPerc{SolutionNotify3} = '';
			        $valid_id = 2;
			    }
			    
			    undef $Success;
			    $Success =$Self->{ESCLObject}->ESCLAdd(
			        SLAID => $GetPerc{SLAID},
			        Level => 3,
			        Type => 'ST',
			        ValidID => $valid_id,
			        Notify_To => $GetPerc{SolutionRole3},
			        Notify_Perc => $GetPerc{SolutionNotify3},
			        
			    );
		    
			if ( !$Success ) {
			        $Error{Message} = $Self->{LogObject}->GetLogEntry(
			        Type => 'Error',
			        What => 'Message',
			        );
			        $Success = 1; 
			}
		    
		%Error = ();
            #End of main else part
	    }
              
	   # close(FF);
	    
            if ( !%Error ) {

                # update preferences
                my %SLAData = $Self->{SLAObject}->SLAGet(
                    SLAID  => $GetParam{SLAID},
                    UserID => $Self->{UserID},
                );
                my %Preferences = ();
                if ( $Self->{ConfigObject}->Get('SLAPreferences') ) {
                    %Preferences = %{ $Self->{ConfigObject}->Get('SLAPreferences') };
                }
		
		for my $Item ( sort keys %Preferences ) {
                    my $Module = $Preferences{$Item}->{Module}
                        || 'Kernel::Output::HTML::SLAPreferencesGeneric';
			
                    # load module
                    if ( !$Self->{MainObject}->Require($Module) ) {
                        return $Self->{LayoutObject}->FatalError();
                    }
                    my $Object = $Module->new(
                        %{$Self},
                        ConfigItem => $Preferences{$Item},
                        Debug      => $Self->{Debug},
                    );
                    my $Note;
                    my @Params = $Object->Param( SLAData => \%SLAData );
                    if (@Params) {
                        my %GetParam = ();
                        for my $ParamItem (@Params) {
                            my @Array
                                = $Self->{ParamObject}->GetArray( Param => $ParamItem->{Name} );
                            $GetParam{ $ParamItem->{Name} } = \@Array;
                        }
                        if ( !$Object->Run( GetParam => \%GetParam, SLAData => \%SLAData ) ) {
                            $Note .= $Self->{LayoutObject}->Notify( Info => $Object->Error() );
                        }
                    }
                } ## for my $Item sort keys %Preferences 
                return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" );
            } ## End of if  !%Error 
        } ## if no errors occurred

        # header
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Error{Message}
            ? $Self->{LayoutObject}->Notify(
            Priority => 'Error',
            Info     => $Error{Message},
            )
            : '';

        # html output
        $Output .= $Self->_MaskNew(
            %Param,
            %GetParam,
            %Error,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
	
    } ## elsif $Self->{Subaction} eq 'ESCLSave'  

    # ------------------------------------------------------------ #
    # escl overview
    # ------------------------------------------------------------ #
    else {

        # output header
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();

        # check if service is enabled to use it here
        if ( !$Self->{ConfigObject}->Get('Ticket::Service') ) {
            $Output .= $Self->{LayoutObject}->Notify(
                Priority => 'Error',
                Data     => '$Text{"Please activate %s first!", "Service"}',
                Link =>
                    '$Env{"Baselink"}Action=AdminSysConfig;Subaction=Edit;SysConfigGroup=Ticket;SysConfigSubGroup=Core::Ticket#Ticket::Service',
            );
        }

        # output overview
        $Self->{LayoutObject}->Block(
            Name => 'Overview',
            Data => {
                %Param,
            },
        );

        $Self->{LayoutObject}->Block( Name => 'ActionList' );
        $Self->{LayoutObject}->Block( Name => 'ActionAdd' );

        # output overview result
        $Self->{LayoutObject}->Block(
            Name => 'OverviewList',
            Data => {
                %Param,
            },
        );

        # get service list
        my %ServiceList = $Self->{ServiceObject}->ServiceList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $Self->{ValidObject}->ValidList();

        # get sla list
        my %SLAList = $Self->{SLAObject}->SLAList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # if there are any SLA's defined, they are shown
        if (%SLAList) {
            #SLAID:
            for my $SLAID ( sort { lc $SLAList{$a} cmp lc $SLAList{$b} } keys %SLAList ) {

                # get the sla data
                my %SLAData = $Self->{SLAObject}->SLAGet(
                    SLAID  => $SLAID,
                    UserID => $Self->{UserID},
                );

                # build the service list
                my @ServiceList;
                for my $ServiceID ( sort { lc $ServiceList{$a} cmp lc $ServiceList{$b} } @{ $SLAData{ServiceIDs} } ) {
                    push @ServiceList, $ServiceList{$ServiceID} || '-';
                }

                # output overview list row
                $Self->{LayoutObject}->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %SLAData,
                        Service => $ServiceList[0] || '-',
                        Valid => $ValidList{ $SLAData{ValidID} },
                    },
                );

                next if scalar @ServiceList <= 1;

                # remove the first service id
                shift @ServiceList;

                for my $ServiceName (@ServiceList) {

                    # output overview list row
                    $Self->{LayoutObject}->Block(
                        Name => 'OverviewListRow',
                        Data => {
                            Service => $ServiceName,
                        },
                    );
                }
            }
        }

        # otherwise a no data found msg is displayed
        else {
            $Self->{LayoutObject}->Block(
                Name => 'NoDataFoundMsg',
                Data => {},
            );
        }

        # generate output
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminESCL',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    # get params
    my %SLAData;
    my %ESCLData;
    my $SLA_ID; 
     $SLAData{SLAID} = $Self->{ParamObject}->GetParam( Param => 'SLAID' ) || '';

    if ( $SLAData{SLAID} ) {

        $SLA_ID = $SLAData{SLAID};
	# get sla data
        %SLAData = $Self->{SLAObject}->SLAGet(
            SLAID  => $SLAData{SLAID},
            UserID => $Self->{UserID},
        );
	# get escalation matrix
	%ESCLData = $Self->{ESCLObject}->ESCLGet(
	    SLAID  => $SLAData{SLAID},
	    UserID => 1,
	);
	
    }
    else {
        $SLAData{ServiceID} = $Self->{ParamObject}->GetParam( Param => 'ServiceID' );
    }
    

    # get service list
    my %ServiceList = $Self->{ServiceObject}->ServiceList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );

    # generate ServiceOptionStrg
    $Param{ServiceOptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data        => \%ServiceList,
        Name        => 'ServiceIDs',
        SelectedID  => $SLAData{ServiceIDs} || [],
        Multiple    => 1,
        Size        => 5,
        Translation => 0,
        Max         => 200,
    );


    # generate CalendarOptionStrg
    my %CalendarList;
    for my $CalendarNumber ( '', 1 .. 50 ) {
        if ( $Self->{ConfigObject}->Get("TimeVacationDays::Calendar$CalendarNumber") ) {
            $CalendarList{$CalendarNumber} = "Calendar $CalendarNumber - "
                . $Self->{ConfigObject}->Get( "TimeZone::Calendar" . $CalendarNumber . "Name" );
        }
    }
    $SLAData{CalendarOptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%CalendarList,
        Name         => 'Calendar',
        SelectedID   => $Param{Calendar} || $SLAData{Calendar},
        PossibleNone => 1,
    );
    my %NotifyLevelList = (
        10 => '10%',
        20 => '20%',
        30 => '30%',
        40 => '40%',
        50 => '50%',
        60 => '60%',
        70 => '70%',
        80 => '80%',
        90 => '90%',
    );
    
    # generate the valid rolelist and append one temporary for Agent/Owner
    my %RoleLevelList;
    %RoleLevelList = $CommonObject{GroupObject}->RoleList( Valid => 1 );
    $RoleLevelList{-99} = 'Owner';
       
    
    #    ##FR
    $ESCLData{FirstResponseNotify1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'FirstResponseNotify1',
        SelectedID   => $Param{FirstResponseNotify1} || $ESCLData{$SLA_ID}{FR}{1}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{FirstResponseNotify2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'FirstResponseNotify2',
        SelectedID   => $Param{FirstResponseNotify2} || $ESCLData{$SLA_ID}{FR}{2}{Notify_Perc},
        PossibleNone => 1,
    );        
    $ESCLData{FirstResponseNotify3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'FirstResponseNotify3',
        SelectedID   => $Param{FirstResponseNotify3} || $ESCLData{$SLA_ID}{FR}{3}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{FirstResponseRole1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'FirstResponseRole1',
        SelectedID   => $Param{FirstResponseRole1} || $ESCLData{$SLA_ID}{FR}{1}{Notify_To},
        PossibleNone => 1,
    );
    $ESCLData{FirstResponseRole2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'FirstResponseRole2',
        SelectedID   => $Param{FirstResponseRole2} || $ESCLData{$SLA_ID}{FR}{2}{Notify_To},
        PossibleNone => 1,
    );        
    $ESCLData{FirstResponseRole3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'FirstResponseRole3',
        SelectedID   => $Param{FirstResponseRole3} || $ESCLData{$SLA_ID}{FR}{3}{Notify_To},
        PossibleNone => 1,
    );
    ##UT
    $ESCLData{UpdateNotify1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'UpdateNotify1',
        SelectedID   => $Param{UpdateNotify1} || $ESCLData{$SLA_ID}{UT}{1}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{UpdateNotify2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'UpdateNotify2',
        SelectedID   => $Param{UpdateNotify2} || $ESCLData{$SLA_ID}{UT}{2}{Notify_Perc},
        PossibleNone => 1,
    );        
    $ESCLData{UpdateNotify3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'UpdateNotify3',
        SelectedID   => $Param{UpdateNotify3} || $ESCLData{$SLA_ID}{UT}{3}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{UpdateRole1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'UpdateRole1',
        SelectedID   => $Param{UpdateRole1} || $ESCLData{$SLA_ID}{UT}{1}{Notify_To},
        PossibleNone => 1,
    );
    $ESCLData{UpdateRole2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'UpdateRole2',
        SelectedID   => $Param{UpdateRole2} || $ESCLData{$SLA_ID}{UT}{2}{Notify_To},
        PossibleNone => 1,
    );        
    $ESCLData{UpdateRole3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'UpdateRole3',
        SelectedID   => $Param{UpdateRole3} || $ESCLData{$SLA_ID}{UT}{3}{Notify_To},
        PossibleNone => 1,
    );
    ##ST
    $ESCLData{SolutionNotify1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'SolutionNotify1',
        SelectedID   => $Param{SolutionNotify1} || $ESCLData{$SLA_ID}{ST}{1}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{SolutionNotify2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'SolutionNotify2',
        SelectedID   => $Param{SolutionNotify2} || $ESCLData{$SLA_ID}{ST}{2}{Notify_Perc},
        PossibleNone => 1,
    );        
    $ESCLData{SolutionNotify3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%NotifyLevelList,
        Name         => 'SolutionNotify3',
        SelectedID   => $Param{SolutionNotify3} || $ESCLData{$SLA_ID}{ST}{3}{Notify_Perc},
        PossibleNone => 1,
    );
    $ESCLData{SolutionRole1OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'SolutionRole1',
        SelectedID   => $Param{SolutionRole1} || $ESCLData{$SLA_ID}{ST}{1}{Notify_To},
        PossibleNone => 1,
    );
    $ESCLData{SolutionRole2OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'SolutionRole2',
        SelectedID   => $Param{SolutionRole2} || $ESCLData{$SLA_ID}{ST}{2}{Notify_To},
        PossibleNone => 1,
    );        
    $ESCLData{SolutionRole3OptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%RoleLevelList,
        Name         => 'SolutionRole3',
        SelectedID   => $Param{SolutionRole3} || $ESCLData{$SLA_ID}{ST}{3}{Notify_To},
        PossibleNone => 1,
    );
    ###End Here By Rohit Basu
    

    # get valid list
    my %ValidList        = $Self->{ValidObject}->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $SLAData{ValidOptionStrg} = $Self->{LayoutObject}->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $SLAData{ValidID} || $ValidListReverse{valid},
    );

    # output sla edit
    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => {
            %Param
        },
    );

    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionOverview' );

    $Self->{LayoutObject}->Block(
        Name => 'ESCLEdit',
        Data => {
            %Param,
            %SLAData,
	    %ESCLData,
        },
    );

    # shows header
    if ( $SLAData{SLAID} ) {
        $Self->{LayoutObject}->Block( Name => 'HeaderEdit' );
    }
    else {
        $Self->{LayoutObject}->Block( Name => 'HeaderAdd' );
    }

    # show each preferences setting
    my %Preferences = ();
    if ( $Self->{ConfigObject}->Get('SLAPreferences') ) {
        %Preferences = %{ $Self->{ConfigObject}->Get('SLAPreferences') };
    }
    for my $Item ( sort keys %Preferences ) {
        my $Module = $Preferences{$Item}->{Module}
            || 'Kernel::Output::HTML::SLAPreferencesGeneric';

        # load module
        if ( !$Self->{MainObject}->Require($Module) ) {
            return $Self->{LayoutObject}->FatalError();
        }
        my $Object = $Module->new(
            %{$Self},
            ConfigItem => $Preferences{$Item},
            Debug      => $Self->{Debug},
        );
        my @Params = $Object->Param( SLAData => \%SLAData );
        if (@Params) {
            for my $ParamItem (@Params) {
                $Self->{LayoutObject}->Block(
                    Name => 'SLAItem',
                    Data => { %Param, },
                );
                if (
                    ref( $ParamItem->{Data} ) eq 'HASH'
                    || ref( $Preferences{$Item}->{Data} ) eq 'HASH'
                    )
                {
                    $ParamItem->{'Option'} = $Self->{LayoutObject}->BuildSelection(
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                    );
                }
                $Self->{LayoutObject}->Block(
                    Name => $ParamItem->{Block} || $Preferences{$Item}->{Block} || 'Option',
                    Data => {
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                    },
                );
            }
        }
    }

    # get output back
    return $Self->{LayoutObject}->Output( TemplateFile => 'AdminESCL', Data => \%Param );
}

1;

__END__
=pod

=head2 NAME

Kernel::Modules::AdminESCL - escalation interface lib

=head2 DESCRIPTION

This module is a interface module and will be access from interface of OTRS.
The module has dependency with a external system module named Escalation.pm
This module can be called from any perl script.
User can download the module and keep it under Kernel/module/AdminESCL.pm or can get the opm file
from var/packagesetup/MultilevelEscalation-1.0.1 and get installed as bundel in OTRS.

=head2 VERSION

$Revision: 1.0 $ $Date: 2013/02/04 14:38:57 $
$VERSION = qw($Revision: 1.0 $) [1];

=head2 Dependencies

Kernel::System::Escalation

=head2 SYNOPSIS

Helps to create the OTRS interface for the Multilevel escalation.

=head1 PUBLIC INTERFACE

create an object

	use warnings;
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

=head2 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).
This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
