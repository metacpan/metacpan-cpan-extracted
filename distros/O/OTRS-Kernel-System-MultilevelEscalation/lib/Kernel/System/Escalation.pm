# --
# Kernel/System/Escalation.pm - all sla function
# Copyright (C) 2001-2013 OTRS AG, http://otrs.org/
# -- 
# $Id: Escalation.pm, v 1.0 2013/02/04 14:38:57 en Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Escalation;

use strict;
use warnings;



use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.0 $) [1];


sub new {
        my ( $Type, %Param ) = @_;
            
        # allocate new hash for object
        my $Self = {};
        bless( $Self, $Type );
            
        # check needed objects
        for my $Object (qw(DBObject ConfigObject EncodeObject LogObject MainObject)) {
            $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
        }
            
        return $Self;
    }


sub ESCLGet {
        my ( $Self, %Param ) = @_;
        
        # check needed stuff
            for my $Argument (qw(SLAID UserID)) {
                if ( !$Param{$Argument} ) {
                 $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Argument!" );
                 return;
                }
            }
        
        # check if valid sla and update escalation
            #update escalation set valid_id = 2 where sla_id in (select id from sla where valid_id = 2);
            $Self->{DBObject}->Prepare(
                SQL   => 'update escalation set valid_id = 2 where sla_id in (select id from sla where valid_id = 2)',
                );
                
            $Self->{DBObject}->Prepare(
                SQL   => 'update escalation set valid_id = 3 where sla_id in (select id from sla where valid_id = 3)',
                );    
                
            $Self->{DBObject}->Prepare(
                SQL   => 'update escalation set valid_id = 1 where sla_id in (select id from sla where valid_id = 1)',
                );     
                
            # get escalation from db
            $Self->{DBObject}->Prepare(
                SQL => 'SELECT sla_id,  notify_type, level, notify_to, notify_perc, valid_id FROM escalation WHERE valid_id = 1 and  sla_id = ?',
                Bind => [ \$Param{SLAID} ],
            );
            
        # fetch the result
        my %ESCLData;
        my @Row;
        while ( @Row = $Self->{DBObject}->FetchrowArray() ) {
            $ESCLData{$Row[0]}{$Row[1]}{$Row[2]}{Notify_To}   = $Row[3];
            $ESCLData{$Row[0]}{$Row[1]}{$Row[2]}{Notify_Perc} = $Row[4];
            $ESCLData{$Row[0]}{$Row[1]}{$Row[2]}{ValidID} = $Row[5];
        }
        
        return %ESCLData;
    }


sub ESCLAdd {
        my ( $Self, %Param ) = @_;
            
        # check needed stuff
        for my $Argument (qw(SLAID Type Level ValidID)) {
            if ( !$Param{$Argument} ) {
                $Self->{LogObject}->Log(
                    Priority => 'error',
                    Message  => "Need $Argument!",
                );
                return;
            }
        }
        
        # set default values
          $Param{Notify_To}   ||= '';
            
        # find exiting esclation's with the same name
            $Self->{DBObject}->Prepare(
                SQL   => 'SELECT sla_id FROM escalation WHERE sla_id = ? and notify_type = ? and level = ?',
                Bind  => [ \$Param{SLAID}, \$Param{Type}, \$Param{Level} ],
                Limit => 1,
            );
            
            
        # fetch the result
            my $NoAdd;
            while ( $Self->{DBObject}->FetchrowArray() ) {
                $NoAdd = 1;
            }
        
            # abort insert of new sla, if name already exists
            if ($NoAdd) {
                
                $Self->{DBObject}->Prepare(
                    SQL   => 'DELETE FROM escalation WHERE sla_id = ? and notify_type = ? and level = ?',
                    Bind  => [ \$Param{SLAID}, \$Param{Type}, \$Param{Level} ],
                );
               
            }
            undef $NoAdd;
          
        # add escalation to database
            return if !$Self->{DBObject}->Do(
                
             SQL => 'INSERT INTO escalation '
             .  '(sla_id,  notify_type, level, notify_to, '
             . 'notify_perc, valid_id) VALUES '
             . '(?, ?, ?, ?, ?, ?)',
             Bind => [
             \$Param{SLAID}, \$Param{Type}, \$Param{Level}, \$Param{Notify_To}, \$Param{Notify_Perc}, \$Param{ValidID},
             ],
        );
        
        # get inserted data
            return if !$Self->{DBObject}->Prepare(
                 SQL   => 'SELECT sla_id FROM escalation WHERE sla_id = ? and notify_type = ? and level = ?',
                 Bind  => [ \$Param{SLAID}, \$Param{Type}, \$Param{Level} ],
                 Limit => 1,
            );
     
        # fetch the result
            my $SLAID;
            while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
                $SLAID = $Row[0];
            }
       
        # check escalation sla_id
            if ( !$SLAID ) {
                $Self->{LogObject}->Log(
                    Priority => 'error',
                    Message  => "Can't find SLAID for '$Param{SLAID}'!",
                );
            return;
            }
            
            #update escalation set valid_id = 2 where sla_id in (select id from sla where valid_id = 2);
            $Self->{DBObject}->Prepare(
                SQL   => 'update escalation set valid_id = 2 where sla_id in (select id from sla where valid_id = 2)',
                );
                
            $Self->{DBObject}->Prepare(
                SQL   => 'update escalation set valid_id = 3 where sla_id in (select id from sla where valid_id = 3)',
                );
           
        return $SLAID;
    }

1;


__END__
=pod

=head2 NAME

Kernel::System::Escalation - escalation lib

=head2 VERSION

$Revision: 1.0 $ $Date: 2013/02/04 14:38:57 $
$VERSION = qw($Revision: 1.0 $) [1];

=head2 Dependencies

No such extra dependency, general OTRS 3.1.x will do.

=head2 DESCRIPTION

This module is a core sysyem module and will be access from interface module of OTRS.
The module has direct relation to a new table 'escalation' in the database.
The module helps to add escalation by the function ESCLAdd().
The module helps to get escalation related to a ticket by the function ESCLGet().
The related interface module which use this module is AdminESCL.pm
User can download the module and keep it under Kernel/System/Escalation.pm or can get the opm file
from var/packagesetup/MultilevelEscalation-1.0.1 and get installed as bundel in OTRS.

=head2 SYNOPSIS

All escalation functions.

=head1 PUBLIC INTERFACE

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::Escalation;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $ESCLObject = Kernel::System::Esclation->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
    );

=head1 ESCLGet()

Return a sla as hash

        Return
            $ESCLData{SLAID}{Notify_Type}{Level}{Notify_To};
            $ESCLData{SLAID}{Notify_Type}{Level}{Notify_Perc};
            $ESCLData{SLAID}{Notify_Type}{Level}{Valid_ID};
            


        my %ESCLData = $SLAObject->ESCLGet(
                SLAID  => 123,
                UserID => 1,
            );
        

=head1 ESCLAdd()

Add a escalation

    my $SLAID = $SLAObject->ESCLAdd(
        SLAID       => 1, ### From [ 1, 2, 3 ] depends on ticket SLAID,
        Type        => 'FR', ### From [FR, UT, ST],
        Level       => 1, ### From [1, 2, 3 ] can be increased,
        Notify_To   => Rolename,
        Notify_Perc => 60,  # if response escalation is 60% reached
        ValidID     => 1,
        
    );

=head2 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).
This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.


=cut
