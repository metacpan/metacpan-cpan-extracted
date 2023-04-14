#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2018-06-14
# @package SubProcess Management
# @subpackage Spawn Subprocesses and read their Output and Errors

# This Module defines Classes to manage multiple Subprocesses read their Output and Errors
# It forks the Main Process to execute the Sub Process Funcionality
#
#---------------------------------
# Requirements:
# - The Perl Package "perl-Data-Dump" must be installed
#
#---------------------------------
# Features:
# - Sub Process Execution Time Out
#

#==============================================================================
# The ChildProcessExecutable Package

package ChildProcessExecutable;

#----------------------------------------------------------------------------
#Dependencies

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = undef;

    #Set the Default Attributes and assign the initial Values
    $self = {
        "_method_execute" => undef,
        "_report"         => "",
        "_error_message"  => "",
        "_error_code"     => 0,
        @_
    };

    #Bestow Objecthood
    bless $self, $class;

    $self->{"_method_execute"} = $self->getExecute;

    #Give the Object back
    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub setExecute {
    my $self   = shift;
    my $refexe = shift;

    if ( defined $refexe ) {

        #Accept only Code References
        if ( ref $refexe eq "CODE" ) {
            $self->{"_method_execute"} = $refexe;
        }
    }
    else    #The Code Reference Parameter is undefined
    {
        $self->{"_method_execute"} = $refexe;
    }       #if(defined $refexe)

    return $refexe;
}

sub Execute {
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getExecute {
    my $self   = shift;
    my $refexe = $self->{"_method_execute"};

    unless ( defined $refexe ) {
        $refexe = sub {
            return $self->Execute;
        };
    }    #unless(defined $refexe)

    return $refexe;
}

sub getReportString {
    my $self = shift;

    return $self->{"_report"};
}

sub getErrorCode {
    my $self = shift;

    return $self->{"_error_code"};
}

sub getErrorString {
    my $self = shift;

    return $self->{"_error_message"};
}

return 1;

