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
# The ChildProcess Package

package ChildProcess;

#----------------------------------------------------------------------------
#Dependencies

use POSIX ":sys_wait_h";
use IO::Select;

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = undef;

    #Set the Default Attributes and assign the initial Values
    $self = {
        "_pid"            => -1,
        "_name"           => "",
        "_executable"     => undef,
        "_log_pipe"       => undef,
        "_error_pipe"     => undef,
        "_pipe_selector"  => undef,
        "_report"         => "",
        "_error_message"  => "",
        "_error_code"     => 0,
        "_process_status" => -1,
        @_
    };

    #Bestow Objecthood
    bless $self, $class;

    #Give the Object back
    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub setName {
    my $self = shift;

    $self->{"_name"} = shift;

    $self->{"_name"} = "" unless ( defined $self->{"_name"} );
}

sub setExecutable {
    my $self   = shift;
    my $prcexe = shift;

    $self->{"_executable"} = $prcexe
      if ( $prcexe->isa("ChildProcessExecutable") );
}

sub Launch {
    my $self = shift;

    my @arrexeprms = @_;
    my $irs        = 0;

    if ( defined $self->{"_executable"} ) {
        if ( ( $self->{"_executable"} )->isa("ChildProcessExecutable") ) {

            #------------------------
            #Process forks before Executing the Code

            my $refexe = $self->{"_executable"}->getExecute;

            #Execute the ChildProcessExecutable Code
            $refexe->(@arrexeprms);

        }
        else {
            $self->{"_error_message"} =
              "Execute failed.\n" . "Executable Function is not set.\n";

            $self->{"_error_code"} = 2
              unless ( defined $self->{"_error_code"} );
            $self->{"_error_code"} = 2 if ( $self->{"_error_code"} < 2 );
        }    #if(($self->{"_executable"})->isa("ChildProcessExecutable"))
    }
    else     #Executable Function is not set
    {
        $self->{"_error_message"} =
          "Execute failed.\n" . "Executable Function is not set.\n";

        $self->{"_error_code"} = 3 unless ( defined $self->{"_error_code"} );
        $self->{"_error_code"} = 3 if ( $self->{"_error_code"} < 3 );
    }        #if(defined $self->{"_executable"})

    return $irs;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getProcessID {
    my $self = shift;

    return $self->{"_pid"};
}

sub getName {
    my $self = shift;

    return $self->{"_name"};
}

sub isRunning {
    my $self = shift;
    my $irng = 0;

    $irng = 0 if ( $self->{"_pid"} > 0
        && $self->{"_process_status"} < 0 );

    return $irng;
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

sub getProcessStatus {
    my $self = shift;

    return $self->{"_process_status"};
}

