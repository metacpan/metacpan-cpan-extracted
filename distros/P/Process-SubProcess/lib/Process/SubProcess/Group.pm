#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2020-09-20
# @package SubProcess Management
# @subpackage Process/SubProcess/Group.pm

# This Module defines a Class to manage multiple SubProcess Objects read their Output and Errors
#
#---------------------------------
# Requirements:
# - The Perl Package "perl-Data-Dump" must be installed
# - The Perl Module "Process/SubProcess.pm" must be installed
#
#---------------------------------
# Extensions:
# - The Perl Module "Process/ChildProcess.pm" must be installed
#
#---------------------------------
# Features:
# - Sub Process Execution Time Out
#

BEGIN {
    use lib '../../../lib';
}    #BEGIN

#==============================================================================
# The Process::SubProcess::Group Package

package Process::SubProcess::Group;

#----------------------------------------------------------------------------
#Dependencies

use POSIX qw(strftime);
use Scalar::Util 'blessed';
use Data::Dump qw(dump);

use Process::SubProcess;

#----------------------------------------------------------------------------
#Constructors

sub new {

    #Take the Method Parameters
    my ( $invocant, %hshprms ) = @_;
    my $class = ref($invocant) || $invocant;
    my $self  = undef;

    #Set the Default Attributes and assign the initial Values
    $self = {
        '_array_processes'   => [],
        '_list_processes'    => {},
        '_check_interval'    => -1,
        '_read_timeout'      => -1,
        '_execution_timeout' => -1,
        '_start_time'        => -1,
        '_report'            => '',
        '_error_message'     => '',
        '_error_code'        => 0,
        '_profiling'         => 0,
        '_debug'             => 0,
        '_quiet'             => 0
    };

    if ( scalar( keys %hshprms ) > 0 ) {

        #Set initial Values
        $self->{'_debug'} = $hshprms{'debug'} if ( defined $hshprms{'debug'} );
        $self->{'_quiet'} = $hshprms{'quiet'} if ( defined $hshprms{'quiet'} );
    }    #if(scalar(keys %hshprms) > 0)

    #Bestow Objecthood
    bless $self, $class;

    if ( scalar( keys %hshprms ) > 0 ) {

        #Execute initial Configurations
        $self->setCheckInterval( $hshprms{'check'} )
          if ( defined $hshprms{'check'} );
        $self->setReadTimeout( $hshprms{'read'} )
          if ( defined $hshprms{'read'} );
        $self->setReadTimeout( $hshprms{'readtimeout'} )
          if ( defined $hshprms{'readtimeout'} );
        $self->setTimeout( $hshprms{'timeout'} )
          if ( defined $hshprms{'timeout'} );
    }    #if(scalar(keys %hshprms) > 0)

    #Give the Object back
    return $self;
}

sub DESTROY {
    my $self = $_[0];

    #Free the System Resources
    #$self->freeResources;
}

#----------------------------------------------------------------------------
#Administration Methods

sub add {
    my $self = shift;

    my $rsprc  = undef;
    my $sprctp = "";

    print "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{"_debug"} > 0 && $self->{"_quiet"} < 1 );

    if ( scalar(@_) > 0 ) {

        #Read the 2nd Parameter
        $rsprc = shift;
    }

    #2nd Parameter is given
    if ( defined $rsprc ) {
        $sprctp = blessed $rsprc;

        #The 2nd Parameter is not an Object
        unless ( defined $sprctp ) {

            #Scalar Parameter has been given
            $sprctp = $rsprc;

            #No Object has been given
            $rsprc = undef;

            #Read the 3rd Parameter
            $rsprc = shift if ( scalar(@_) > 0 );

        }    #unless(defined $sprctp)
    }    #if(defined $rsprc)

    unless ( defined $rsprc ) {
        if ( $sprctp ne "" ) {
            $rsprc = $sprctp->new;
        }
        else    #No Parameters given
        {
            #Create a Process::SubProcess Object by Default
            $rsprc = Process::SubProcess::->new;
        }
    }    #unless(defined $rsprc)

    if (   $self->{"_debug"} > 0
        && $self->{"_quiet"} < 1 )
    {
        print "self 0 dmp:\n" . dump($self);
        print "\n";

        print "rs prc 1 dmp:\n" . dump($rsprc);
        print "\n";
    }    #if($self->{"_debug"} > 0 && $self->{"_quiet"} < 1)

    if ( defined $rsprc ) {
        unless ( $rsprc->isa("Process::ChildProcess")
            || $rsprc->isa("Process::SubProcess") )
        {
            $rsprc = undef;

            $rsprc = Process::SubProcess::->new;
        }
    }
    else    #Sub Process Object was not created yet
    {
        #Create a SubProcess Object by Default
        $rsprc = Process::SubProcess::->new;
    }       #if(defined $rsprc)

    if ( defined $rsprc ) {
        if (   $rsprc->isa('Process::ChildProcess')
            || $rsprc->isa('Process::SubProcess') )
        {
            push @{ $self->{_array_processes} }, ($rsprc);

            $rsprc->setReadTimeout( $self->{'_read_timeout'} )
              if ( $self->{'_read_timeout'} > 0 );

            $rsprc->setProfiling( $self->{'_profiling'} )
              if ( $self->{'_profiling'} > 0 );

        }    #if($rsprc->isa("ChildProcess") || $rsprc->isa("SubProcess"))
    }    #if(defined $rsprc)

    if (   $self->{'_debug'} > 0
        && $self->{'_quiet'} < 1 )
    {
        print "self 1 dmp:\n" . dump($self);
        print "\n";
    }

    #Give the Object back
    return $rsprc;
}

sub setCheckInterval {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_check_interval"} = shift;

        #The Parameter is not a Number
        $self->{"_check_interval"} = -1
          unless ( $self->{"_check_interval"} =~ /^-?\d+$/ );
    }
    else    #No Parameters given
    {
        #Remove the Check Interval
        $self->{"_check_interval"} = -1;
    }       #if(scalar(@_) > 0)

    $self->{"_check_interval"} = -1
      unless ( defined $self->{"_check_interval"} );

    if ( $self->{"_check_interval"} > 0
        && scalar( @{ $self->{"_array_processes"} } ) > 0 )
    {
        my $irdtmout = sprintf( "%d",
            $self->{"_check_interval"} /
              scalar( @{ $self->{"_array_processes"} } ) );

        #Save the required Read Timeout
        $self->setReadTimeout($irdtmout);
    } #if($self->{"_check_interval"} > 0 && scalar(@{$self->{"_array_processes"}}) > 0)
}

sub setReadTimeout {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_read_timeout"} = shift;

        #The Parameter is not a Number
        $self->{"_read_timeout"} = 1
          unless ( $self->{"_read_timeout"} =~ /^-?\d+$/ );
    }
    else    #No Parameters given
    {
        #Set Minimum Read Timeout
        $self->{"_read_timeout"} = 1;
    }       #if(scalar(@_) > 0)

    #Set the Minimum Read Timeout
    $self->{"_read_timeout"} = 1 unless ( defined $self->{"_read_timeout"} );

    #Set the Minimum Read Timeout
    $self->{"_read_timeout"} = 1 if ( $self->{"_read_timeout"} < 1 );

    if ( defined $self->{"_array_processes"} ) {
        if ( scalar( @{ $self->{"_array_processes"} } ) > 0 ) {
            my $sbprc = undef;

            foreach $sbprc ( @{ $self->{"_array_processes"} } ) {

                #Communicate the Change to all Sub Processes
                $sbprc->setReadTimeout( $self->{"_read_timeout"} );

            }    #foreach $sbprc (@{$self->{"_array_processes"}})
        }    #if(scalar(@{$self->{"_array_processes"}}) > 0)
    }    #if(defined $self->{"_array_processes"})
}

sub setTimeout {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_execution_timeout"} = shift;

        $self->{"_execution_timeout"} = -1
          unless ( $self->{"_execution_timeout"} =~ /^-?\d+$/ );
    }
    else    #No Parameter was given
    {
        $self->{"_execution_timeout"} = -1;
    }       #if(scalar(@_) > 0)

    $self->{"_execution_timeout"} = -1
      unless ( defined $self->{"_execution_timeout"} );

    $self->{"_execution_timeout"} = -1
      if ( $self->{"_execution_timeout"} < -1 );
}

sub setProfiling {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_profiling"} = shift;

        #The Parameter is not a Number
        $self->{"_profiling"} = 0 unless ( $self->{"_profiling"} =~ /^-?\d+$/ );
    }
    else    #No Parameters given
    {
        #Remove the Check Interval
        $self->{"_profiling"} = 1;
    }       #if(scalar(@_) > 0)

    $self->{"_profiling"} = 0 unless ( defined $self->{"_profiling"} );

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc = undef;

        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {

            #Communicate the Change to all Sub Processes
            $sbprc->setProfiling( $self->{"_profiling"} );

        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})

}

sub setDebug {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_debug"} = shift;

        $self->{"_debug"} = 0 unless ( $self->{"_debug"} =~ /^-?\d+$/ );
    }
    else    #No Parameter was given
    {
        $self->{"_debug"} = 1;
    }       #if(scalar(@_) > 0)

    $self->{"_debug"} = 1 unless ( defined $self->{"_debug"} );

    if ( $self->{"_debug"} > 1 ) {
        $self->{"_debug"} = 1;
    }
    elsif ( $self->{"_debug"} < 0 ) {
        $self->{"_debug"} = 0;
    }
}

sub setQuiet {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_quiet"} = shift;

        $self->{"_quiet"} = 0 unless ( $self->{"_quiet"} =~ /^-?\d+$/ );
    }
    else    #No Parameter was given
    {
        $self->{"_quiet"} = 1;
    }       #if(scalar(@_) > 0)

    $self->{"_quiet"} = 1 unless ( defined $self->{"_quiet"} );

    if ( $self->{"_quiet"} > 1 ) {
        $self->{"_quiet"} = 1;
    }
    elsif ( $self->{"_quiet"} < 0 ) {
        $self->{"_quiet"} = 0;
    }
}

sub Launch {
    my $self    = $_[0];
    my $irs     = 0;
    my $iprccnt = scalar( @{ $self->{'_array_processes'} } );

    $self->{'_report'} .=
      "" . ( caller(0) )[3] . " - go ...\n" . "arr prcs cnt: '$iprccnt'\n"
      if ( $self->{'_debug'} );

    if ( $iprccnt > 0 ) {
        my $sbprc   = undef;
        my $sprcnm  = '';
        my $iprcidx = -1;

        my @arrnow = undef;
        my $stmnow = '';

        if (   $self->{'_check_interval'} > 0
            && $self->{'_read_timeout'} > 0
            && $self->{'_read_timeout'} * $iprccnt >
            $self->{'_check_interval'} )
        {
            #Reestablish the Check Interval
            $self->setCheckInterval( $self->{'_check_interval'} );
        }

        if ( $self->{'_execution_timeout'} > -1 ) {

            #Keep track of the Start Time
            $self->{'_start_time'} = time;
        }

        for ( $iprcidx = 0 ; $iprcidx < $iprccnt ; $iprcidx++ ) {
            $sbprc = $self->{'_array_processes'}[$iprcidx];

            if ( defined $sbprc ) {
                $sprcnm = "No. '$iprcidx' - " . $sbprc->getNameComplete;

                @arrnow = localtime;
                $stmnow = strftime( '%F %T', @arrnow );

                $self->{'_report'} .=
                  "$stmnow : Sub Process ${sprcnm}: Launching ...\n";

                #Launch the Sub Process through Process::SubProcess::Launch()
                if ( $sbprc->Launch ) {
                    @arrnow = localtime;
                    $stmnow = strftime( '%F %T', @arrnow );

                    $self->{'_report'} .=
                        "$stmnow : Sub Process ${sprcnm}: Launch OK "
                      . "- PID ("
                      . $sbprc->getProcessID . ")\n";

                    $irs++;
                }
                else    #Sub Process Launch failed
                {
                    #Keep the Sub Process Error Code
                    $self->{'_error_code'} = $sbprc->getErrorCode
                      if ( $sbprc->getErrorCode > $self->{'_error_code'} );

                    $self->{'_error_message'} .=
                        "Sub Process ${sprcnm}: Launch failed!"
                      . "Message: "
                      . $sbprc->getErrorString;
                }       #if($sbprc->Launch)
            }    #if(defined $sbprc)
        }    #for($iprcidx = 0; $iprcidx < $iprccnt; $iprcidx++)
    }    #if($iprccnt > 0)

    return $irs;
}

sub Check {
    my $self    = $_[0];
    my $irs     = 0;
    my $iprccnt = scalar( @{ $self->{'_array_processes'} } );

    $self->{'_report'} .=
      "" . ( caller(0) )[3] . " - go ...\n" . "arr prcs cnt: '$iprccnt'\n"
      if ( $self->{'_debug'} );

    if ( $iprccnt > 0 ) {
        my $sbprc   = undef;
        my $sprcnm  = '';
        my $iprcidx = -1;

        my @arrnow = undef;
        my $stmnow = '';

        my $ichkgo = 1;

        for ( $iprcidx = 0 ; $ichkgo && $iprcidx < $iprccnt ; $iprcidx++ ) {
            $sbprc = $self->{'_array_processes'}[$iprcidx];

            if ( defined $sbprc ) {
                $sprcnm = $sbprc->getNameComplete;

                $self->{"_report"} .= "Sub Process ${sprcnm}: checking ...\n"
                  if ( $self->{"_debug"} > 0 );

                if ( $sbprc->isRunning ) {
                    if ( $sbprc->Check ) {

                        #Count the Running Sub Processes
                        $irs++;
                    }
                    else    #The Sub Process has finished
                    {
                        @arrnow = localtime;
                        $stmnow = strftime( '%F %T', @arrnow );

                        $self->{"_report"} .=
                            "$stmnow : Sub Process ${sprcnm}: "
                          . "finished with ["
                          . $sbprc->getProcessStatus . "]\n";

                        #$sbprc->freeResources;
                    }       #if($sbprc->Check)

                    if ( $self->{'_execution_timeout'} > -1 ) {

                        #Stop the Checks on Execution Timeout
                        $ichkgo = 0
                          if (
                            time - $self->{'_start_time'} >
                            $self->{'_execution_timeout'} );
                    }
                }
                else        #The Sub Process is already finished
                {
                    if ( $sbprc->getProcessID > 0 ) {
                        $self->{"_report"} .=
                            "Sub Process ${sprcnm}: "
                          . "already finished with ["
                          . $sbprc->getProcessStatus . "]\n"
                          if ( $self->{"_debug"} > 0 );

                        #$sbprc->freeResources;
                    }       #if($sbprc->getProcessID > 0)
                }    #if($sbprc->isRunning)
            }    #if(defined $sbprc)
        }    #for($iprc = 0; $ichkgo && $iprc < $iprccnt; $iprc++)
    }    #if($iprccnt > 0)

    #Count the Running Sub Processes
    return $irs;
}

sub checkiProcess {
    my $self  = shift;
    my $sbprc = undef;
    my $iidx  = shift;
    my $irs   = 0;

    $sbprc = $self->getiProcess($iidx);

    if ( defined $sbprc ) {
        $irs = 0;

        $irs = $sbprc->Check if ( $sbprc->isRunning );
    }    #if(defined $sbprc)

    return $irs;
}

sub Wait {

    #Take the Method Parameters
    my ( $self, %hshprms ) = @_;
    my $irng = -1;
    my $irs  = 0;

    my $itmchk     = -1;
    my $itmchkstrt = -1;
    my $itmchkend  = -1;
    my $itmrng     = -1;
    my $itmrngstrt = -1;
    my $itmrngend  = -1;

    $self->{'_report'} .= "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{'_debug'} );

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setCheckInterval( $hshprms{'check'} )
          if ( defined $hshprms{'check'} );
        $self->setReadTimeout( $hshprms{'read'} )
          if ( defined $hshprms{'read'} );
        $self->setReadTimeout( $hshprms{'readtimeout'} )
          if ( defined $hshprms{'readtimeout'} );
        $self->setTimeout( $hshprms{'timeout'} )
          if ( defined $hshprms{'timeout'} );
    }    #if(scalar(keys %hshprms) > 0)

    #Set the Start Time if it is not set yet
    $self->{'_start_time'} = time if ( $self->{'_start_time'} < 1 );

    do    #while($irng > 0);
    {
        if (   $self->{'_check_interval'} > -1
            || $self->{'_execution_timeout'} > -1 )
        {
            if ( $itmchkstrt < 1 ) {

                #Take the Time measured at Launch Time
                $itmchkstrt = $self->{'_start_time'};
            }
            else    #It is not the first Check
            {
                $itmchkstrt = time;
            }       #if($itmchkstrt < 1)

            if ( $self->{'_execution_timeout'} > -1 ) {
                if ( $itmrngstrt < 1 ) {
                    $itmrng     = 0;
                    $itmrngstrt = $itmchkstrt;
                }
            }       #if($self->{"_execution_timeout"} > -1)
        } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)

        #Check the Sub Process
        $irng = $self->Check;

        if ( $irng > 0 ) {
            if (   $self->{"_check_interval"} > -1
                || $self->{"_execution_timeout"} > -1 )
            {
                $itmchkend = time;
                $itmrngend = $itmchkend;

                $itmchk = $itmchkend - $itmchkstrt;
                $itmrng = $itmrngend - $itmrngstrt;

                $self->{'_report'} .=
                  "wait - tm rng: '$itmrng'; tm chk: '$itmchk'\n"
                  if ( $self->{"_debug"} );

                if (   $self->{"_execution_timeout"} > -1
                    && $itmrng >= $self->{"_execution_timeout"} )
                {
                    $self->{"_error_message"} .=
                        "Sub Processes 'Count: $irng': Execution timed out!\n"
                      . "Execution Time '$itmrng / "
                      . $self->{"_execution_timeout"} . "'\n"
                      . "Processes will be terminated.\n";

                    $self->{"_error_code"} = 4
                      if ( $self->{"_error_code"} < 4 );

                    $self->Terminate;
                    $irng = -1;
                } #if($self->{"_execution_timeout"} > -1 && $itmrng >= $self->{"_execution_timeout"})

                if (   $irng > 0
                    && $itmchk < $self->{"_check_interval"} )
                {
                    $self->{'_report'} .=
                        "wait - sleep '"
                      . ( $self->{"_check_interval"} - $itmchk )
                      . "' s ...\n"
                      if ( $self->{"_debug"} );

                    sleep( $self->{"_check_interval"} - $itmchk );
                }
            } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)
        }    #if($irng > 0)
    } while ( $irng > 0 );

    if ( $irng == 0 ) {

        #Mark as Finished correctly
        $irs = 1;
    }
    elsif ( $irng < 0 ) {

        #Mark as Failed if the Sub Process was Terminated
        $irs = 0;
    }    #if($irng == 0)

    return $irs;
}

sub Run {

    #Take the Method Parameters
    my ( $self, %hshprms ) = @_;
    my $irs = 0;

    $self->{'_report'} .= "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{'_debug'} );

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setCheckInterval( $hshprms{'check'} )
          if ( defined $hshprms{'check'} );
        $self->setReadTimeout( $hshprms{'read'} )
          if ( defined $hshprms{'read'} );
        $self->setReadTimeout( $hshprms{'readtimeout'} )
          if ( defined $hshprms{'readtimeout'} );
        $self->setTimeout( $hshprms{'timeout'} )
          if ( defined $hshprms{'timeout'} );
    }

    if ( $self->Launch ) {
        $irs = $self->Wait;
    }
    else    #Sub Process Launch failed
    {
        $self->{'_error_message'} .= "Sub Processes: Process Launch failed!\n";
    }       #if($self->Launch)

    return $irs;
}

sub Terminate {
    my $self = $_[0];

    $self->{"_report"} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{"_debug"} );
    $self->{"_error_message"} .= "Sub Processes: Processes terminating ...\n";

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc = undef;

        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {
            if ( $sbprc->isRunning ) {

                #Terminate the Sub Process
                $sbprc->Terminate;
            }    #if($sbprc->isRunning)
        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})

}

sub Kill {
    my $self = $_[0];

    $self->{"_report"} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{"_debug"} );
    $self->{"_error_message"} .= "Sub Processes: Processes killing ...\n";

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc = undef;

        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {
            if ( $sbprc->isRunning ) {

                #Kill the Sub Process
                $sbprc->Kill;
            }    #if($sbprc->isRunning)
        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})
}

sub freeResources {
    my $self = $_[0];

    $self->{"_report"} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{"_debug"} );

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc = undef;

        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {

            #Free all Sub Processes System Resources
            $sbprc->freeResources;
        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})
}

sub clearErrors() {
    my $self    = $_[0];
    my $sdbgmsg = '';

    $sdbgmsg =
      "'" . ( caller(1) )[3] . "' : Call on '" . ( caller(0) )[3] . "'\n"
      if ( $self->{'_debug'} );

    if ( defined $self->{'_array_processes'} ) {
        my $sbprc = undef;

        foreach $sbprc ( @{ $self->{'_array_processes'} } ) {

            #Clear all Sub Processes Errors too
            $sbprc->clearErrors;
        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})

    $self->{'_report'}        = '';
    $self->{'_error_message'} = '';
    $self->{'_error_code'}    = 0;
    $self->{'_start_time'}    = -1;

    #Readd last Debug Message
    $self->{'_report'} .= $sdbgmsg if ( $self->{'_debug'} );
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getiProcess {
    my $self  = $_[0];
    my $rsprc = undef;
    my $iidx  = $_[1];

    #Index must be a positive whole Number
    if ( $iidx =~ /^\d+$/ ) {
        if ( defined $self->{"_array_processes"} ) {
            if ( $iidx < scalar( @{ $self->{"_array_processes"} } ) ) {
                $rsprc = $self->{"_array_processes"}[$iidx];
            }
        }    #if(defined $self->{"_array_processes"})
    }    #if($iidx =~ /^\d+$/)

    return $rsprc;
}

sub getCheckInterval {
    return $_[0]->{'_check_interval'};
}

sub getReadTimeout {
    return $_[0]->{'_read_timeout'};
}

sub getTimeout {
    return $_[0]->{'_execution_timeout'};
}

sub getProcessCount {
    return scalar( @{ $_[0]->{"_array_processes"} } );
}

sub getRunningCount {
    my $self = $_[0];
    my $irng = 0;

    if ( defined $self->{"_array_processes"} ) {
        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {
            $irng++ if ( $sbprc->isRunning );
        }
    }    #if(defined $self->{"_array_processes"})

    return $irng;
}

sub getFreeCount {
    my $self = $_[0];
    my $ifr  = 0;

    if ( defined $self->{"_array_processes"} ) {
        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {
            $ifr++ unless ( $sbprc->isRunning );
        }
    }    #if(defined $self->{"_array_processes"})

    return $ifr;
}

sub getFinishedCount {
    my $self   = $_[0];
    my $ifnshd = 0;

    if ( defined $self->{"_array_processes"} ) {
        foreach $sbprc ( @{ $self->{"_array_processes"} } ) {
            unless ( $sbprc->isRunning ) {

            #The Sub Process was launched and has finished and was not reset yet
                $ifnshd++ if ( $sbprc->getProcessID > 0 );
            }
        }    #foreach $sbprc (@{$self->{"_array_processes"}})
    }    #if(defined $self->{"_array_processes"})

    return $ifnshd;
}

sub getReportString {
    return \$_[0]->{"_report"};
}

sub getErrorString {
    return \$_[0]->{"_error_message"};
}

sub getErrorCode {
    return $_[0]->{"_error_code"};
}

sub isProfiling {
    return $_[0]->{"_profiling"};
}

sub isDebug {
    return $_[0]->{"_debug"};
}

sub isQuiet {
    return $_[0]->{"_quiet"};
}

return 1;
