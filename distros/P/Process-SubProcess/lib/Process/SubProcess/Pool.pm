#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2020-03-21
# @package SubProcess Management
# @subpackage Process/SubProcess/Pool.pm

# This Module defines a Class to manage multiple SubProcess Objects read their Output and Errors
# It extends the SubProcess::Group Functionality to limit the amount of created
# SubProcess Objects and check for finished SubProcess Objects
#
#---------------------------------
# Requirements:
# - The Perl Package "perl-Data-Dump" must be installed
# - The Perl Module "Process/SubProcess/Group.pm" must be installed
#
#---------------------------------
# Features:
#

BEGIN {
    use lib '../../../lib';
}    #BEGIN

#==============================================================================
# The Process::SubProcess::Pool Package

package Process::SubProcess::Pool;

#----------------------------------------------------------------------------
#Dependencies

use parent 'Process::SubProcess::Group';

use POSIX qw(strftime);
use Scalar::Util 'blessed';

use Data::Dump qw(dump);

use Process::SubProcess;

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = undef;

    #Take the Method Parameters
    my %hshprms = @_;

    $self = $class->SUPER::new(@_);

    if ( defined $hshprms{"minprocesscount"} ) {

        #Set additional Configuations
        $self->{"_min_process_count"} = $hshprms{"minprocesscount"};
    }
    else {
        $self->{"_min_process_count"} = -1;
    }

    if ( defined $hshprms{"maxprocesscount"} ) {

        #Set additional Configuations
        $self->{"_max_process_count"} = $hshprms{"maxprocesscount"};
    }
    else {
        $self->{"_max_process_count"} = -1;
    }

    if ( $self->{"_min_process_count"} > 0 ) {
        my $iminprccnt = $self->{"_min_process_count"};
        my $iprccnt    = scalar( @{ $self->{"_array_processes"} } );

        $iminprccnt = $self->{"_max_process_count"}
          if ( $self->{"_max_process_count"} > 0
            && $self->{"_max_process_count"} < $self->{"_min_process_count"} );

        for ( ; $iprccnt < $iminprccnt ; $iprccnt++ ) {

            #Create empty SubProcess Objects
            $self->SUPER::add;
        }    #for(; $iprccnt < $iminprccnt; $iprccnt++)
    }    #if($self->{"_min_process_count"} > 0)

    #Give the Object back
    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub add {
    my $self    = shift;
    my $rsprc   = undef;
    my $iobjprm = 0;
    my $irs     = 0;

    print "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{"_debug"} > 0 && $self->{"_quiet"} < 1 );

    if ( scalar(@_) > 0 ) {
        $iobjprm = 1 if ( defined blessed $_[0] );
    }

    if ( defined $self->{"_max_process_count"}
        && $self->{"_max_process_count"} > 0 )
    {
        #Call Base Class Method
        $rsprc = $self->SUPER::add(@_)
          if ( $self->getProcessCount < $self->{"_max_process_count"} );

    }
    else    #Pool Max Limit is not defined
    {
        #Call Base Class Method
        $rsprc = $self->SUPER::add(@_);
    }

    $irs = 1 if ( defined $rsprc );

    if (   $self->{"_debug"} > 0
        && $self->{"_quiet"} < 1 )
    {
        print "self 1 dmp:\n" . dump($self);
        print "\n";
    }

    if ($iobjprm) {

        #Give the Result back
        return $irs;
    }
    else {
        #Give the Object back
        return $rsprc;
    }
}

sub setMinProcessCount {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_min_process_count"} = shift;

        #The Parameter is not a Number
        $self->{"_min_process_count"} = -1
          unless ( $self->{"_min_process_count"} =~ /^-?\d+$/ );
    }
    else    #No Parameters given
    {
        #Remove the Min Process Count
        $self->{"_min_process_count"} = -1;
    }       #if(scalar(@_) > 0)

    $self->{"_min_process_count"} = -1
      unless ( defined $self->{"_min_process_count"} );

    if ( $self->{"_min_process_count"} > 0 ) {
        my $iminprccnt = $self->{"_min_process_count"};
        my $iprccnt    = scalar( @{ $self->{"_array_processes"} } );

        $iminprccnt = $self->{"_max_process_count"}
          if ( $self->{"_max_process_count"} > 0
            && $self->{"_max_process_count"} < $self->{"_min_process_count"} );

        for ( ; $iprccnt < $iminprccnt ; $iprccnt++ ) {

            #Create empty SubProcess Objects
            $self->SUPER::add;
        }    #for(; $iprccnt < $iminprccnt; $iprccnt++)
    }    #if($self->{"_min_process_count"} > 0)
}

sub setMaxProcessCount {
    my $self = shift;

    if ( scalar(@_) > 0 ) {
        $self->{"_max_process_count"} = shift;

        #The Parameter is not a Number
        $self->{"_max_process_count"} = -1
          unless ( $self->{"_max_process_count"} =~ /^-?\d+$/ );
    }
    else    #No Parameters given
    {
        #Remove the Max Process Count
        $self->{"_max_process_count"} = -1;
    }       #if(scalar(@_) > 0)

    $self->{"_max_process_count"} = -1
      unless ( defined $self->{"_max_process_count"} );

}

sub waitFirst {
    my $self = shift;

    #Take the Method Parameters
    my %hshprms = @_;
    my $irs     = 0;

    my $icnt = $self->getProcessCount;
    my $irng = -1;

    my $itmchk     = -1;
    my $itmchkstrt = -1;
    my $itmchkend  = -1;
    my $itmrng     = -1;
    my $itmrngstrt = -1;
    my $itmrngend  = -1;

    print "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{"_debug"} > 0 && $self->{"_quiet"} < 1 );

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setCheckInterval( $hshprms{"check"} )
          if ( defined $hshprms{"check"} );
        $self->setTimeout( $hshprms{"timeout"} )
          if ( defined $hshprms{"timeout"} );
    }

    do    #while($irng == $icnt);
    {
        if (   $self->{"_check_interval"} > -1
            || $self->{"_execution_timeout"} > -1 )
        {
            $itmchkstrt = time;

            if ( $self->{"_execution_timeout"} > -1 ) {
                if ( $itmrngstrt < 1 ) {
                    $itmrng     = 0;
                    $itmrngstrt = $itmchkstrt;
                }
            }    #if($self->{"_execution_timeout"} > -1)
        } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)

        #Check the Sub Processes
        $irng = $self->Check;

        print "rng cnt '$irng / $icnt'\n"
          if ( $self->{"_debug"} > 0
            && $self->{"_quiet"} < 1 );

        if ( $irng == $icnt ) {
            if (   $self->{"_check_interval"} > -1
                || $self->{"_execution_timeout"} > -1 )
            {
                $itmchkend = time;
                $itmrngend = $itmchkend;

                $itmchk = $itmchkend - $itmchkstrt;
                $itmrng = $itmrngend - $itmrngstrt;

                if (   $self->{"_debug"} > 0
                    && $self->{"_quiet"} < 1 )
                {
                    print "wait tm chk: '$itmchk / "
                      . $self->{"_check_interval"} . "'\n";
                    print "wait tm rng: '$itmrng'\n";
                }

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
                    print "wait sleep '"
                      . ( $self->{"_check_interval"} - $itmchk )
                      . "' s ...\n"
                      if ( $self->{"_debug"} > 0
                        && $self->{"_quiet"} < 1 );

                    #Wait for the Next Check
                    sleep( $self->{"_check_interval"} - $itmchk );

                }    #if($irng > 0 && $itmchk < $self->{"_check_interval"})
            } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)
        }    #if($irng == $icnt)
    } while ( $irng == $icnt );

    unless ( $irng < 0 ) {

        #Mark as Finished correctly
        $irs = 1;
    }

    return $irs;
}

sub waitNext {
    my $self = shift;

    #Take the Method Parameters
    my %hshprms = @_;
    my $irs     = 0;

    my $sbprc = undef;
    my $icnt  = $self->getProcessCount;
    my $irng  = -1;

    my $itmchk     = -1;
    my $itmchkstrt = -1;
    my $itmchkend  = -1;
    my $itmrng     = -1;
    my $itmrngstrt = -1;
    my $itmrngend  = -1;

    print "" . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{"_debug"} > 0 && $self->{"_quiet"} < 1 );

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setCheckInterval( $hshprms{"check"} )
          if ( defined $hshprms{"check"} );
        $self->setTimeout( $hshprms{"timeout"} )
          if ( defined $hshprms{"timeout"} );
    }

    do    #while($irng == $icnt);
    {
        if (   $self->{"_check_interval"} > -1
            || $self->{"_execution_timeout"} > -1 )
        {
            $itmchkstrt = time;

            if ( $self->{"_execution_timeout"} > -1 ) {
                if ( $itmrngstrt < 1 ) {
                    $itmrng     = 0;
                    $itmrngstrt = $itmchkstrt;
                }
            }    #if($self->{"_execution_timeout"} > -1)
        } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)

        #Check if some Sub Process has finished
        $sbprc = $self->getFinishedProcess;

        unless ( defined $sbprc ) {

            #Check the Sub Processes
            $irng = $self->Check;

            #Check if some Sub Process has finished
            $sbprc = $self->getFinishedProcess;

            print "rng cnt '$irng / $icnt'\n"
              if ( $self->{"_debug"} > 0
                && $self->{"_quiet"} < 1 );

            if (   $self->{"_check_interval"} > -1
                || $self->{"_execution_timeout"} > -1 )
            {
                $itmchkend = time;
                $itmrngend = $itmchkend;

                $itmchk = $itmchkend - $itmchkstrt;
                $itmrng = $itmrngend - $itmrngstrt;

                if (   $self->{"_debug"} > 0
                    && $self->{"_quiet"} < 1 )
                {
                    print "wait tm chk: '$itmchk / "
                      . $self->{"_check_interval"} . "'\n";
                    print "wait tm rng: '$itmrng'\n";
                }

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

                if (   !defined $sbprc
                    && $irng > 0
                    && $itmchk < $self->{"_check_interval"} )
                {
                    print "wait sleep '"
                      . ( $self->{"_check_interval"} - $itmchk )
                      . "' s ...\n"
                      if ( $self->{"_debug"} > 0
                        && $self->{"_quiet"} < 1 );

                    #Wait for the Next Check
                    sleep( $self->{"_check_interval"} - $itmchk );

                }    #if(! defined $sbprc  && $irng > 0
                     # && $itmchk < $self->{"_check_interval"})
            } #if($self->{"_check_interval"} > -1 || $self->{"_execution_timeout"} > -1)
        }    #unless(defined $sbprc)
      } while ( !defined $sbprc
        && $irng > 0 );

    if ( $irng <= 0 ) {

        #Mark as Finished correctly
        $irs = 1;
    }    #if($irng <= 0)

    return $irs;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getFreeProcess {
    my $self  = shift;
    my $rsprc = undef;

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc   = undef;
        my $iprcidx = 0;
        my $iprccnt = scalar( @{ $self->{"_array_processes"} } );

        for (
            $iprcidx = 0 ;
            !defined $rsprc && $iprcidx < $iprccnt ;
            $iprcidx++
          )
        {
            $sbprc = $self->{"_array_processes"}[$iprcidx];

            if ( defined $sbprc ) {
                $rsprc = $sbprc unless ( $sbprc->isRunning );
            }    #if(defined $sbprc)
        } #for($iprcidx = 0; ! defined $rsprc && $iprcidx < $iprccnt; $iprcidx++)
    }    #if(defined $self->{"_array_processes"})

    return $rsprc;
}

sub getFinishedProcess {
    my $self  = shift;
    my $rsprc = undef;

    if ( defined $self->{"_array_processes"} ) {
        my $sbprc   = undef;
        my $iprcidx = 0;
        my $iprccnt = scalar( @{ $self->{"_array_processes"} } );

        for (
            $iprcidx = 0 ;
            !defined $rsprc && $iprcidx < $iprccnt ;
            $iprcidx++
          )
        {
            $sbprc = $self->{"_array_processes"}[$iprcidx];

            if ( defined $sbprc ) {
                unless ( $sbprc->isRunning ) {

            #The Sub Process was launched and has finished and was not reset yet
                    $rsprc = $sbprc if ( $sbprc->getProcessID > 0 );
                }
            }    #if(defined $sbprc)
        } #for($iprcidx = 0; ! defined $rsprc && $iprcidx < $iprccnt; $iprcidx++)
    }    #if(defined $self->{"_array_processes"})

    return $rsprc;
}

sub getMinProcessCount {
    my $self = shift;

    return $self->{"_min_process_count"};
}

sub getMaxProcessCount {
    my $self = shift;

    return $self->{"_max_process_count"};
}

return 1;
