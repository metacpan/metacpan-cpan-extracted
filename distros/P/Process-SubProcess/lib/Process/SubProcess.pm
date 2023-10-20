#---------------------------------
# @author Bodo (Hugo) Barwich
# @version 2023-10-07
# @package SubProcess Management
# @subpackage Process/SubProcess.pm

# This Module defines the Class to manage a Subprocess and read its Output and Errors
# It launches the Command with IPC::Open3
#
#---------------------------------
# Requirements:
# - The Perl Package "perl-Time-HiRes" must be installed
#
#---------------------------------
# Features:
# - Sub Process Execution Time Out
#

#==============================================================================
# The Process::SubProcess Package

=head1 NAME

Process::SubProcess - Library to manage Sub Processes as objects

=cut

package Process::SubProcess;

#----------------------------------------------------------------------------
#Dependencies

use version;
use Exporter qw(import);    # gives you Exporter's import() method directly

our @EXPORT_OK = qw(runSubProcess);    # symbols to export on request

use POSIX ":sys_wait_h";
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday);

use IO::Select;

use IPC::Open3;
use Symbol qw(gensym);

our $VERSION = '2.1.9';

=head1 DESCRIPTION

C<Process::SubProcess> implements a class to manage a Sub Process and read its Output and Errors

The Idea of this API is to launch Sub Processes and keep track of all Output
on C<STDOUT>, C<STDERR>, the C<EXIT CODE> and possible System Errors at Launch Time
in an object oriented manner.
This allows an easy aggregation and thus the creation of Sub Process Groups and Sub Process Pools
for simultaneous execution of multiple Sub Processes while keeping the execution logs
separated.

=cut

# =head1 OVERVIEW

#----------------------------------------------------------------------------
#Static Methods

use constant FLAG_STDIN  => 0;
use constant FLAG_STDOUT => 1;
use constant FLAG_STDERR => 2;
use constant FLAG_ANYOUT => 3;

=head1 STATIC METHODS

=over 4

=item runSubProcess ( [ COMMAND | OPTIONS ] )

This creates adhoc an C<Process::SubProcess> Object and runs the command given as string.

C<COMMAND> - is a single scalar parameter will be interpreted as command to executed
without any additional options.

C<OPTIONS> - are passed in a hash like fashion, using key and value pairs.
Combining the command with additional C<OPTIONS> also requires the hash key C<command> to be set.

See L<Method C<setArrProcess()>|/"setArrProcess ( CONFIGURATIONS )">

=back

=cut

sub runSubProcess {
    my $sbprc = Process::SubProcess::new('Process::SubProcess');

    my %hshprms = undef;

    #Return the Processing Report
    my @arrrs = ();
    my $irs   = 0;

    if ( scalar(@_) > 1 ) {

        #Take the Method Parameters
        %hshprms = @_;
    }
    else {
        #One single Parameter
        %hshprms = ( 'command' => $_[0] );
    }

    $sbprc->setArrProcess(%hshprms);

    $irs = $sbprc->Run();

    push @arrrs, ( $sbprc->getReportString );
    push @arrrs, ( $sbprc->getErrorString );

    if ( $sbprc->getProcessStatus > -1 ) {
        push @arrrs, ( $sbprc->getProcessStatus );
    }
    else    #The Process could not be launched
    {
        push @arrrs, ($irs);
    }

    $sbprc->freeResources;

    $sbprc = undef;

    return @arrrs;
}

#----------------------------------------------------------------------------
#Constructors

=head1 CONSTRUCTOR

=over 4

=item new ( [ CONFIGURATIONS ] )

This is the constructor for a new SubProcess.

B<Parameters:>

C<CONFIGURATIONS> are passed in a hash like fashion, using key and value pairs.

See L<Method C<setArrProcess()>|/"setArrProcess ( CONFIGURATIONS )">

=back

=cut

sub new {

    #Take the Method Parameters
    my ( $invocant, %hshprms ) = @_;
    my $class = ref($invocant) || $invocant;
    my $self  = undef;

    #Set the Default Attributes
    $self = {
        '_pid'               => -1,
        '_name'              => '',
        '_command'           => undef,
        '_input_pipe'        => undef,
        '_log_pipe'          => undef,
        '_error_pipe'        => undef,
        '_pipe_selector'     => undef,
        '_pipe_flags'        => undef,
        '_package_size'      => 8192,
        '_read_timeout'      => 0,
        '_execution_timeout' => -1,
        '_report'            => '',
        '_error_message'     => '',
        '_error_code'        => 0,
        '_process_status'    => -1,
        '_start_time'        => -1,
        '_end_time'          => -1,
        '_execution_time'    => -1,
        '_profiling'         => 0,
        '_debug'             => 0
    };

    #Set initial Values
    $self->{'_name'}    = $hshprms{'name'} if ( defined $hshprms{'name'} );
    $self->{'_command'} = $hshprms{'command'}
      if ( defined $hshprms{'command'} );

    #Bestow Objecthood
    bless $self, $class;

    #Execute initial Configurations
    $self->setReadTimeout( $hshprms{'check'} ) if ( defined $hshprms{'check'} );
    $self->setReadTimeout( $hshprms{'read'} )  if ( defined $hshprms{'read'} );
    $self->setReadTimeout( $hshprms{'readtimeout'} )
      if ( defined $hshprms{'readtimeout'} );
    $self->setTimeout( $hshprms{'timeout'} ) if ( defined $hshprms{'timeout'} );
    $self->setProfiling( $hshprms{'profiling'} )
      if ( defined $hshprms{'profiling'} );
    $self->setDebug( $hshprms{'debug'} ) if ( defined $hshprms{'debug'} );

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

=head1 Administration Methods

=over 4

=item setArrProcess ( CONFIGURATIONS )

This Method will asign Values to physically Data Fields.

B<Parameters:>

C<CONFIGURATIONS> - is a list are passed in a hash like fashion, using key and value pairs.

B<Recognized Configurations:>

C<name> - is a string that will be assigned as the process name.
This is useful when there are several processes with the same command running and
a more prettier readable name is desired.

C<command> - The command that has to be executed. It only can be set if the process is not
running yet

C<timeout> - Time in seconds to wait for the process to finish. After this time the process will
be terminated

C<check | read | readtimeout> - Time in seconds to wait for the process output.
If the process is expected to run longer it is useful to set it to avoid excessive checks.
It is also important for multiple process execusions, because other processes will not
be checked before the read has not timed out.

C<debug> - show internal processing information

C<quiet> - do not print any warnings or errors

See L<Method C<setName()>|/"setName ( NAME )">

See L<Method C<setCommand()>|/"setCommand ( COMMAND )">

See L<Method C<setTimeout()>|/"setTimeout ( TIMEOUT )">

See L<Method C<setReadTimeout()>|/"setReadTimeout ( TIMEOUT )">

=back

=cut

sub setArrProcess {

    #Take the Method Parameters
    my ( $self, %hshprms ) = @_;

    #Set the Name
    $self->{'_name'} = $hshprms{'name'} if ( defined $hshprms{'name'} );

    $self->setReadTimeout( $hshprms{'check'} ) if ( defined $hshprms{'check'} );
    $self->setReadTimeout( $hshprms{'read'} )  if ( defined $hshprms{'read'} );
    $self->setReadTimeout( $hshprms{'readtimeout'} )
      if ( defined $hshprms{'readtimeout'} );
    $self->setTimeout( $hshprms{'timeout'} ) if ( defined $hshprms{'timeout'} );
    $self->setDebug( $hshprms{'debug'} )     if ( defined $hshprms{'debug'} );

    #Attributes that cannot be changed in Running State
    unless ( $self->isRunning ) {
        $self->setCommand( $hshprms{'command'} )
          if ( defined $hshprms{'command'} );
        $self->setProfiling( $hshprms{'profiling'} )
          if ( defined $hshprms{'profiling'} );
    }    #unless($self->isRunning)
}

=pod

=over 4

=item set ( CONFIGURATIONS )

Shorthand for C<setArrProcess()>

See L<Method C<setArrProcess()>|/"setArrProcess ( CONFIGURATIONS )">

=back

=cut

sub set {

    #Pass the Parameters on to Process::SubProcess::setArrProcess()
    Process::SubProcess::setArrProcess(@_);
}

=pod

=over 4

=item setName ( NAME )

This Method will asign a Name to the process.

The C<NAME> of the C<Process::SubProcess> object will reflect in the logs.

This is useful when there are several processes with the same command running and
a more prettier readable name is desired.

B<Parameters:>

C<NAME> - is a string that will be assigned as the process name.

=back

=cut

sub setName {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        $self->{'_name'} = $_[1];
    }
    else {
        $self->{'_name'} = '';
    }
}

=pod

=over 4

=item setCommand ( COMMAND )

This method sets the C<COMMAND> property as string that represents the command to be executed.

It can only be set when the Sub Process is not running.

B<Parameters:>

C<COMMAND> - is a single scalar parameter that will be interpreted as command to executed

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub setCommand {
    my $self = $_[0];

    #Attributes that cannot be changed in Running State
    unless ( $self->isRunning ) {
        if ( scalar(@_) > 1 ) {
            $self->{'_command'} = $_[1];
        }

        $self->{'_command'} = '' unless ( defined $self->{'_command'} );

        $self->{'_pid'}            = -1;
        $self->{'_process_status'} = -1;
    }    #unless($self->isRunning)
}

=pod

=over 4

=item setReadTimeout ( TIMEOUT )

This method sets the C<READTIMEOUT> property as numeric value that represents
the time in seconds to wait for the command output.
If the process is expected to run longer it is useful to set it to avoid excessive checks.
It is also important for multiple process execusions, because other processes will not
be checked before the read has not timed out.
It can only be set when the Sub Process is not running.

B<Parameters:>

C<TIMEOUT> - is an integer that specifies how long the manager will be waiting for output.

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub setReadTimeout {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        $self->{'_read_timeout'} = $_[1];

        #Set the Default Read Timeout
        $self->{'_read_timeout'} = 0
          unless ( $self->{'_read_timeout'} =~ /^-?\d+$/ );
    }
    else    #No Parameter was given
    {
        #Enable the Read Timeout
        #Set the Minimum Read Timeout
        $self->{'_read_timeout'} = 1;
    }    #if(scalar(@_) > 1)

    #Set the Default Read Timeout
    $self->{'_read_timeout'} = 0 unless ( defined $self->{'_read_timeout'} );

    if ( $self->{'_read_timeout'} < 0 ) {

        #Disable the Read Timeout
        $self->{'_read_timeout'} = 0;
    }
}

=pod

=over 4

=item setTimeout ( TIMEOUT )

This method sets the C<EXECUTIONTIMEOUT> property as numeric value that represents
the Time in seconds to wait for the process to finish. After this time the process will
be terminated.

The C<EXECUTIONTIMEOUT> property must be a positive numeric value. Setting it to a
negative value C< -1 > will disable the Execution Timeout

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<Terminate()>|/"Terminate ()">

=back

=cut

sub setTimeout {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        if ( $_[1] =~ /^\d+$/ ) {
            $self->{'_execution_timeout'} = $_[1];
        }
        else    #The Parameter is not an unsigned whole Number
        {
            $self->{'_execution_timeout'} = -1;
        }
    }
    else        #No Parameter was given
    {
        $self->{'_execution_timeout'} = -1;
    }           #if(scalar(@_) > 1)
}

=pod

=over 4

=item setProfiling ( PROFILING )

This method activated the B<Execution Time> measuring.

It can only be set when the Sub Process is not running.

B<Parameters:>

C<PROFILING> - whole number to enable or disable the profiling. Negative numbers or C< 0 >
will disable it. Positive numbers or C< 1 > will enable it.

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub setProfiling {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        $self->{'_profiling'} = $_[1];

        #The Parameter is not a Number
        $self->{'_profiling'} = 0 unless ( $self->{'_profiling'} =~ /^-?\d+$/ );
    }
    else        #No Parameter was given
    {
        #Enable Profiling
        $self->{'_profiling'} = 1;
    }           #if(scalar(@_) > 1)

    $self->{'_profiling'} = 0 unless ( defined $self->{'_profiling'} );

    if ( $self->{'_profiling'} > 1 ) {
        $self->{'_profiling'} = 1;
    }
    elsif ( $self->{'_profiling'} < 0 ) {
        $self->{'_profiling'} = 0;
    }
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

=pod

=over 4

=item Launch ()

This method starts the process. It will create a Sub Process from the defined C<COMMAND>
Property.

Per default this the process runs asynchronously. The L<Wait()> method is used to
monitor its execution and read its outputs

B<Returns:> It returns C< 1 > when the process was launched correctly.
otherwise it returns C< 0 >.

See L<Method C<Check()>|/"Check ()">

=back

=cut

sub Launch {
    my $self = $_[0];
    my $irs  = 0;

    my $sprcnm = $self->getNameComplete;

    $self->{'_report'} .= '' . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{'_debug'} );

    $self->{'_pid'} = -1;

    if ( defined $self->{'_command'}
        && $self->{'_command'} ne '' )
    {
        # handles for stdin/stdout/stderr
        my $inputwriter = undef;
        my $logreader   = undef;
        my $errorreader = undef;

        my $serr = '';

        $errorreader = gensym;

        $self->{'_report'} .= "Sub Process ${sprcnm}: Launching ...\n"
          if ( $self->{'_debug'} );

        #------------------------
        #Execute the configured Command

        $self->{'_report'} .= "cmd: '" . $self->{'_command'} . "'\n"
          if ( $self->{'_debug'} );

#print "sleep 30 sec: go ...\n" if($self->{"_debug"} > 0 && $self->{"_quiet"} < 1);

        #sleep 30;

#print "sleep 30 sec: done.\n" if($self->{"_debug"} > 0 && $self->{"_quiet"} < 1);

        $self->{'_report'} .= "cmd pfg '" . $self->{'_profiling'} . "'\n"
          if ( $self->{'_debug'} );

        if ( $self->{'_profiling'} ) {
            $self->{'_start_time'} = gettimeofday;
        }

        eval {
            #Reset any previous Errors
            $! = 0;

            #Spawn the Child Process
            $self->{'_pid'} = open3( $inputwriter, $logreader, $errorreader,
                $self->{'_command'} );

        };    #eval

        if ($@) {
            $self->{'_pid'} = -1;

            # Check for open3() Exception
            # according to documentation at :
            # https://perldoc.perl.org/IPC/Open3.html
            if ( $@ =~ qr/^open3: (.*)$/m ) {
                $serr = $1;
            }
            else {
                $serr = $@;
            }

            #Cut Script Reference off
            $serr = $1 if ( $serr =~ qr/(.*) at .* line .*\./ );

            $self->{'_error_message'} .=
                "ERROR: Sub Process ${sprcnm}: Launch failed with Exception!\n"
              . "Message: '$serr'\n";

            #Mark the Command as failed
            $self->{'_error_code'} = 1 if ( $self->{'_error_code'} < 1 );
        }    #if($@)

        if ( defined $self->{'_pid'}
            && $self->{'_pid'} > 0 )
        {
            #The open3() Call has succeeded

            #Suppressing the System Error 29 silently
            $! = 0 if ( ( $! + 0 ) == 29 );

        }

        if ($!) {
            $self->{'_pid'}            = -1;
            $self->{'_process_status'} = ( $! + 0 );

            $self->{'_error_message'} .=
              "ERROR: Sub Process ${sprcnm}: Launch failed with System Error ["
              . $self->{'_process_status'} . "]\n"
              . "Message: '$!'\n";

            #Mark the Command as failed
            $self->{'_error_code'} = 1 if ( $self->{'_error_code'} < 1 );
        }    #if($!)

        # Check whether parent/child process
        if ( $self->{'_pid'} > 0 ) {

            #------------------------
            #Sub Process Launch succeeded

            $self->{'_process_status'} = -1;
            $self->{'_execution_time'} = -1;

            $self->{'_input_pipe'} = $inputwriter;
            $self->{'_log_pipe'}   = $logreader;
            $self->{'_error_pipe'} = $errorreader;

            $self->{'_pipe_selector'} = IO::Select->new();

            #Close the Process Input Pipe
            close $self->{'_input_pipe'};

            $self->{'_pipe_selector'}->add($logreader);
            $self->{'_pipe_selector'}->add($errorreader);

            $self->{'_pipe_readbytes'} = 0;

            $self->{'_report'} .=
              "Sub Process ${sprcnm}: Launch OK - PID ("
              . $self->{'_pid'} . ")\n"
              if ( $self->{'_debug'} );

        }    #if($iprcpid > 0)
    }
    else     #Executable Command is empty
    {
        $self->{'_error_message'} .=
            "ERROR: Sub Process '${sprcnm}' Launch failed!\n"
          . "Executable Command is not set or is empty.\n";

        $self->{'_error_code'} = 2 unless ( defined $self->{'_error_code'} );
        $self->{'_error_code'} = 2 if ( $self->{'_error_code'} < 2 );

    }        #if(defined $self->{"_command"} && $self->{"_command"} ne "")

    #The Launch was successful if a Process ID was given
    $irs = 1 if ( $self->{'_pid'} > 0 );

    return $irs;
}

=pod

=over 4

=item Check ()

This method checks whether the process is finished and calls the C<Read()> method to
read its output.

B<Returns:> It returns C< 1 > when the process is still running
otherwise it returns C< 0 >.

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub Check {
    my $self = $_[0];

    my $sprcnm = $self->getNameComplete;
    my $irng   = 0;

    if ( $self->{'_debug'} ) {
        $self->{'_report'} .=
          "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n";
        $self->{'_report'} .= '' . ( caller(0) )[3] . " - go ...\n";
    }    #if($self->{'_debug'})

    if ( defined $self->{'_pid'}
        && $self->{'_pid'} > -1 )
    {
        #------------------------
        #Check Child Process running or finished

        my $ifnshpid = -1;

        $ifnshpid = waitpid( $self->{'_pid'}, WNOHANG );

        $self->{'_report'} .= ""
          . ( caller(0) )[3]
          . " - wait on ("
          . $self->{'_pid'}
          . ") - fnsh pid: ($ifnshpid); stt cd: [$?]\n"
          if ( $self->{'_debug'} );

        if ( $ifnshpid > -1 ) {
            if ( $ifnshpid == 0 ) {

                #------------------------
                #The Child Process is running

                $irng = 1;

                $self->{'_report'} .=
                  "prc (" . $self->{'_pid'} . "): Read checking ...\n"
                  if ( $self->{'_debug'} );

                #Read the Messages from the Sub Process
                $self->Read;

            }
            else    #A finished Process ID was returned
            {
                #------------------------
                #A Child Process has finished

                $self->{'_report'} .= "prc ($ifnshpid): done.\n"
                  if ( $self->{'_debug'} );

                if ( $ifnshpid == $self->{'_pid'} ) {

                    #------------------------
                    #The own Child Process has finished

                    $self->{'_report'} .= "cmd fnshd [" . $? . "].\n"
                      if ( $self->{'_debug'} );

                    #Read the Process Status Code
                    $self->{'_process_status'} = ( $? >> 8 );

                    if ( $self->{'_profiling'} ) {
                        $self->{'_end_time'} = gettimeofday;

                        $self->{'_execution_time'} = sprintf( "%.6f",
                            $self->{'_end_time'} - $self->{'_start_time'} );

                        $self->{'_report'} .=
                          "Time Execution: '"
                          . $self->{'_execution_time'} . "' s\n"
                          if ( $self->{'_debug'} );

                    }    #if($self->{"_profiling"})

                    if ( $self->{'_process_status'} >= 0 ) {
                        $self->{'_report'} .=
                            "cmd stt cd: '$? / "
                          . $self->{'_process_status'} . " >> "
                          . ( $? >> 8 ) . "'\n"
                          if ( $self->{'_debug'} );

                        if ($!) {

                            #Read the Error Code
                            $self->{'_process_status'} = ( $! + 0 );

                            #Read the Error Message
                            $self->{'_error_message'} .=
                                "Message ["
                              . $self->{'_process_status'}
                              . "]: '$!'\n";
                        }    #if($!)
                    }
                    else     #A Negative Error Code was given
                    {
                        if ($!) {

                            #Read the Error Code
                            $self->{'_process_status'} = ( $! + 0 );

                            #Read the Error Message
                            $self->{'_error_message'} .=
                                "Command '"
                              . $self->{'_command'}
                              . "': Command failed with ["
                              . $self->{'_process_status'} . "]!\n"
                              . "Message: '$!'\n";
                        }
                        else    #Error Code is not set
                        {
                            #Failure without Error Code or Message
                            $self->{'_error_message'} .=
                                "Command '"
                              . $self->{'_command'}
                              . "': Command failed with ["
                              . $self->{'_process_status'} . "]!\n";
                        }       #if($!)
                    }    #if($self->{'_process_status'} >= 0)

                    if ( $self->{'_process_status'} != 0 ) {

                        #Mark the Command as failed
                        $self->{'_error_code'} = 1
                          if ( $self->{'_error_code'} < 1
                            || $self->{'_error_code'} == 4 );

                    }    #if($self->{'_process_status'} != 0)

                    $self->{'_pipe_readbytes'} = 0
                      if ( $self->{'_pipe_readbytes'} < 1 );

                    #Read the Last Messages from the Sub Process
                    $self->Read;

                    #Close the Process Log Message Pipe
                    close $self->{"_log_pipe"};

                    #Close the Process Error Message Pipe
                    close $self->{"_error_pipe"};

                }
                else    #Process ID does not match
                {
                    $self->{"_error_message"} .= "ERROR: Process ($ifnshpid): "
                      . "Unknown Process finished.\n";

                    $self->{"_error_code"} = 1
                      if ( $self->{"_error_code"} < 1 );

                }       #if($ifnshpid == $self->{"_pid"})
            }    #if($ifnshpid > 0)
        }
        else     #Sub Process ID is set but the Process does not exist
        {
            if ( $self->{"_process_status"} < 0 ) {

					      #------------------------
					      # The Child Process ID was captured
					      # but no Process Status Code was captured

                $self->{"_error_message"} .=
                  "Sub Process ${sprcnm}: Process does not exist.\n";

                $self->{"_error_code"} = 1 if ( $self->{"_error_code"} < 1 );

            }
            else    #The Child Process has already finished
            {

            }       #if($self->{"_process_status"} < 0)
        }    #if($ifnshpid > -1)
    }
    else     #Child Process ID was not captured
    {
        $self->{"_pid"}            = -1 unless ( defined $self->{"_pid"} );
        $self->{"_process_status"} = -1
          unless ( defined $self->{"_process_status"} );
    }        #if(defined $self->{"_pid"} && $self->{"_pid"} > -1)

    #Return the Check Result
    return $irng;
}

=pod

=over 4

=item Read ()

This method reads the C<STDOUT> and C<STDERR> outputs from a running process
which was started with the C<Launch()> method.

When the process is not started yet it does not do anything.

If a C<TIMEOUT> is set through the C<setReadTimeout()> method the B<Manager Process> keeps
waiting for output until the C<TIMEOUT> is fulfilled.

See L<Method C<setReadTimeout()>|/"setReadTimeout ( TIMEOUT )">

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub Read {
    my $self = $_[0];

    $self->{'_report'} .= '' . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{"_debug"} );

    #The Sub Process must have been launched
    if (   defined $self->{'_pid'}
        && defined $self->{'_process_status'}
        && $self->{'_pid'} > 0 )
    {
        my $ppsel = $self->{'_pipe_selector'};

        my $prcpp  = $self->{"_log_pipe"};
        my $prcerr = $self->{"_error_pipe"};

        my $sprcnm = $self->getNameComplete;

        unless ( defined $ppsel ) {

            #------------------------
            #Create Pipe IO Selector

            $ppsel = IO::Select->new();

            $ppsel->add($prcpp)  if ( defined $prcpp );
            $ppsel->add($prcerr) if ( defined $prcerr );

            #Store the Pipe IO Selector Object
            $self->{"_pipe_selector"} = $ppsel;

        }    #unless(defined $self->{"_pipe_selector"})

        if ( defined $ppsel ) {

            #------------------------
            #Read Child Process Message Pipes

            my @arrppselrdy = undef;
            my $ppselfh     = undef;

            my $sppselfhln = "";
            my $irdcnt     = -1;

            $self->{"_report"} .= "prc ("
              . $self->{"_pid"} . ") ["
              . $self->{"_process_status"}
              . "]: try read ...\n"
              if ( $self->{"_debug"} );

            $self->{"_report"} .= "prc ("
              . $self->{"_pid"}
              . "): try read '"
              . $ppsel->count
              . "' pipes\n"
              if ( $self->{"_debug"} );

            while ( @arrppselrdy =
                $ppsel->can_read( $self->{"_read_timeout"} ) )
            {
                foreach $ppselfh (@arrppselrdy) {
                    $irdcnt = sysread( $ppselfh, $sppselfhln,
                        $self->{"_package_size"} );

                    if ( defined $irdcnt ) {
                        if ( $irdcnt > 0 ) {
                            if ( fileno($ppselfh) == fileno($prcpp) ) {
                                $self->{"_report"} .=
                                    "pipe ("
                                  . fileno($ppselfh)
                                  . "): reading report ...\n"
                                  if ( $self->{"_debug"} );

                                $self->{"_report"} .= $sppselfhln;
                            }
                            elsif ( fileno($ppselfh) == fileno($prcerr) ) {
                                $self->{"_report"} .=
                                    "pipe ("
                                  . fileno($ppselfh)
                                  . "): reading error ...\n"
                                  if ( $self->{"_debug"} );

                                $self->{"_error_message"} .= $sppselfhln;
                            }    #if(fileno($ppselfh) == fileno($prcpp))
                        }
                        else     #End of Transmission
                        {
                            $self->{"_report"} .=
                                "pipe ("
                              . fileno($ppselfh)
                              . "): transmission done.\n"
                              if ( $self->{"_debug"} );

                            #Remove the Pipe File Handle
                            $ppsel->remove($ppselfh);

                        }        #if($irdcnt > 0)
                    }
                    else         #Reading from the Pipe failed
                    {
                        #Remove the Pipe File Handle
                        $ppsel->remove($ppselfh);

                        if ($!) {
                            $self->{"_error_message"} .=
                                "ERROR: Sub Process ${sprcnm}: pipe ("
                              . fileno($ppselfh)
                              . "): Read failed with ["
                              . ( $! + 0 ) . "]!\n"
                              . "Message: '$!'\n";

                            $self->{"_error_code"} = 1
                              if ( $self->{"_error_code"} < 1 );

                        }    #if($!)
                    }    #if(defined $irdcnt)
                }    #foreach $ppselfh (@arrjmselrdy)
            }  #while(@arrppselrdy = $ppsel->can_read($self->{"_read_timeout"}))

            $self->{"_report"} .= "prc ("
              . $self->{"_pid"}
              . "): try read done. '"
              . $ppsel->count
              . "' pipes left.\n"
              if ( $self->{"_debug"} );
        }
        else    #Pipe IO Selector could not be created
        {
            $self->{"_error_message"} .=
                "ERROR: Sub Process ${sprcnm}: Read failed!\n"
              . "Message: IO Selector could not be created!\n";

            $self->{"_error_code"} = 1 if ( $self->{"_error_code"} < 1 );

        }       #if(defined $ppsel)
    }    #if(defined $self->{"_pid"} && defined $self->{"_process_status"}
         #	&& $self->{"_pid"} > 0)
}

=pod

=over 4

=item Wait ()

This method calls the C<Check()> method continuously for a started process
which was started with the C<Launch()> method until the C<Check()> method tells that
the process is finished.

If a C<TIMEOUT> is set through the C<setTimeout()> method the B<Manager Process> will
terminate the process after the C<TIMEOUT> is fulfilled.
When a process times out an B<Error Code> of C< 4 > will be set.

B<Returns:> It returns C< 1 > when the process has finished correctly.
It returns C< 0 > when the process had to be terminated.

See L<Method C<Check()>|/"Check ()">

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<Terminate()>|/"Terminate ()">

See L<Method C<setTimeout()>|/"setTimeout ( TIMEOUT )">

=back

=cut

sub Wait {
    my $self = $_[0];

    #Take the Method Parameters
    my %hshprms = @_[ 1 .. $#_ ];
    my $irng    = -1;
    my $irs     = 0;

    my $sprcnm = $self->getNameComplete;

    my $itmrng     = -1;
    my $itmrngstrt = -1;
    my $itmrngend  = -1;

    $self->{'_report'} .= '' . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{'_debug'} );

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setReadTimeout( $hshprms{'check'} )
          if ( defined $hshprms{'check'} );
        $self->setTimeout( $hshprms{'timeout'} )
          if ( defined $hshprms{'timeout'} );
    }

    do    #while($irng > 0);
    {
        if ( $self->{'_execution_timeout'} > -1 ) {
            if ( $itmrngstrt < 1 ) {
                $itmrng     = 0;
                $itmrngstrt = time;
            }
        }    #if($self->{"_execution_timeout"} > -1)

        #Check the Sub Process
        $irng = $self->Check;

        if ( $irng > 0 ) {
            if ( $self->{'_execution_timeout'} > -1 ) {
                $itmrngend = time;

                $itmrng = $itmrngend - $itmrngstrt;

                $self->{'_report'} .= "wait tm rng: '$itmrng'\n"
                  if ( $self->{'_debug'} );

                if ( $itmrng >= $self->{'_execution_timeout'} ) {
                    $self->{'_error_message'} .=
                        "Sub Process ${sprcnm}: Execution timed out!\n"
                      . "Execution Time '$itmrng / "
                      . $self->{'_execution_timeout'} . "'\n"
                      . "Process will be terminated.\n";

                    $self->{'_error_code'} = 4
                      if ( $self->{'_error_code'} < 4 );

                    #Terminate the Timed Out Sub Process
                    $self->Terminate;
                    $irng = -1;
                }    #if($itmrng >= $self->{"_execution_timeout"})
            }    #if($self->{"_execution_timeout"} > -1)
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

=pod

=over 4

=item Run ()

This method starts the process calling the C<Launch()> method and then calls
the C<Wait()> method to wait until the process is finished.

B<Returns:> It returns C< 1 > when the process was started and finished correctly.
It returns C< 0 > when the process could not be started or had to be terminated.

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<Wait()>|/"Wait ()">

=back

=cut

sub Run {
    my $self = $_[0];

    #Take the Method Parameters
    my %hshprms = @_[ 1 .. $#_ ];
    my $irs     = 0;

    $self->{'_report'} .= '' . ( caller(0) )[3] . " - go ...\n"
      if ( $self->{'_debug'} );

    my $sprcnm = $self->getNameComplete;

    if ( scalar( keys %hshprms ) > 0 ) {
        $self->setReadTimeout( $hshprms{'check'} )
          if ( defined $hshprms{'check'} );
        $self->setTimeout( $hshprms{'timeout'} )
          if ( defined $hshprms{'timeout'} );
    }

    if ( $self->Launch ) {
        $irs = $self->Wait();
    }
    else    #Sub Process Launch failed
    {
        $self->{'_error_message'} .=
          "Sub Process ${sprcnm}: Process Launch failed!\n";
    }       #if($self->Launch)

    return $irs;
}

=pod

=over 4

=item Terminate ()

This method sends a C<TERM> signal to the process if it is running.
And then checks the process with the C<Check()> method.

It is used by the B<EXECUTIONTIMEOUT> functionality to ensure that the process does not
run longer than required.

This will include an Error Message "I<Process terminating ...>"
and set the Process C<ERROR CODE> to C< 4 >.

Enabling the C<DEBUG> option will additionally include an B<Activity Information> from
which method C<Terminate()> was called.

See L<Method C<Check()>|/"Check ()">

See L<Method C<setTimeout()>|/"setTimeout ()">

=back

=cut

sub Terminate {
    my $self   = $_[0];
    my $sprcnm = $self->getNameComplete;

    $self->{'_report'} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{'_debug'} );

    if ( $self->isRunning ) {
        $self->{'_error_message'} .=
          "Sub Process ${sprcnm}: Process terminating ...\n";

        kill( 'TERM', $self->{'_pid'} );

        #Mark Process as have been terminated
        $self->{"_error_code"} = 4 if ( $self->{"_error_code"} < 4 );

        $self->Check;
    }
    else    #Sub Process is not running
    {
        $self->{'_error_message'} .=
          "Sub Process ${sprcnm}: Process is not running.\n";
    }       #if($self->isRunning)
}

=pod

=over 4

=item Kill ()

This method sends a C<KILL> signal to the process if it is running.

It is used by the B<EXECUTIONTIMEOUT> functionality to ensure that the process does not
run longer than required.

Any not yet read output will get lost.

This will include an Error Message "I<Process killing ...>"
and set the Process C<ERROR CODE> to C< 4 > and the C<EXIT CODE> to C< 9 >.

Enabling the C<DEBUG> option will additionally include an B<Error Message> from
which method C<Kill()> was called.

See L<Method C<Check()>|/"Check ()">

See L<Method C<setTimeout()>|/"setTimeout ()">

=back

=cut

sub Kill {
    my $self   = shift;
    my $sprcnm = $self->getNameComplete;

    $self->{"_error_message"} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{"_debug"} );

    if ( $self->isRunning ) {
        $self->{"_error_message"} .=
          "Sub Process ${sprcnm}: Process killing ...\n";

        kill( 'KILL', $self->{"_pid"} );

        #Mark Process as have been killed
        $self->{"_process_status"} = 9;
        $self->{"_error_code"}     = 4 if ( $self->{"_error_code"} < 4 );
    }
    else    #Sub Process is not running
    {
        $self->{"_error_message"} .=
          "Sub Process ${sprcnm}: Process is not running.\n";
    }       #if($self->isRunning)
}

sub freeResources {
    my $self = shift;

    $self->{"_report"} .=
      "'" . ( caller(1) )[3] . "' : Signal to '" . ( caller(0) )[3] . "'\n"
      if ( $self->{"_debug"} );

    if ( $self->isRunning > 0 ) {

        #Kill a still running Sub Process
        $self->Kill();
    }

    #Resource can only be freed if the Sub Process has terminated
    if ( $self->isRunning < 1 ) {
        $self->{"_log_pipe"}      = undef;
        $self->{"_error_pipe"}    = undef;
        $self->{"_pipe_selector"} = undef;
    }    #if($self->isRunning < 1)
}

sub clearErrors() {
    my $self = shift;

    $self->{"_pid"}            = -1;
    $self->{"_process_status"} = -1;

    $self->{"_report"}        = "";
    $self->{"_error_message"} = "";
    $self->{"_error_code"}    = 0;
}

#----------------------------------------------------------------------------
#Consultation Methods

=pod

=over 4

=item getProcessID

This Method will return the B<ProcessID> of the process which was assigned by the system
at launch time.

If the process was not launched yet it will return C< -1 >.

B<Returns:> The B<ProcessID> of the process assigned by the system.

See L<Method C<Launch()>|/"Launch ()">

=back

=cut

sub getProcessID {
    return $_[0]->{"_pid"};
}

=pod

=over 4

=item getName

This Method will return the Name to the C<Process::SubProcess> object if any was assigned
with the C<setName()> method.

B<Returns:> The C<NAME> of the C<Process::SubProcess> object as string.

See L<Method C<setName()>|/"setName ( NAME )">

=back

=cut

sub getName {
    return $_[0]->{"_name"};
}

sub getNameComplete {
    my $self = $_[0];
    my $rsnm = '';

    #Identify the Process by its PID if it is running
    $rsnm = '(' . $self->{'_pid'} . ')' if ( $self->{'_pid'} > -1 );
    $rsnm .= ' ' if ( $rsnm ne '' );

    #Identify the Process by its given Name
    $rsnm .= "'" . $self->{'_name'} . "'" if ( $self->{'_name'} ne '' );

    #Identify the Process by its Command
    $rsnm .= "'" . $self->{'_command'} . "'" if ( $rsnm eq '' );

    return $rsnm;
}

sub getCommand {
    return $_[0]->{'_command'};
}

sub getReadTimeout {
    return $_[0]->{'_read_timeout'};
}

sub getTimeout {
    return $_[0]->{'_execution_timeout'};
}

sub isRunning {
    my $self = $_[0];
    my $irng = 0;

    #The Process got a Process ID but did not get a Process Status Code yet
    $irng = 1 if ( $self->{'_pid'} > 0 && $self->{'_process_status'} < 0 );

    return $irng;
}

sub getReportString {
    return \$_[0]->{'_report'};
}

sub getErrorString {
    return \$_[0]->{'_error_message'};
}

sub getErrorCode {
    return $_[0]->{'_error_code'};
}

sub getProcessStatus {
    return $_[0]->{'_process_status'};
}

=pod

=over 4

=item getStartTime ()

This method returns the B<Start Time>. The B<Start Time> is measured at the moment
of the launch of the Sub Process.

This feature has to be enabled with the C<setProfiling()> method.

It has only a value after the Sub Process is launched.

B<Returns:> It returns floating point number representing the time when the Sub Process
was launched.

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<setProfiling()>|/"setProfiling ( PROFILING )">

=back

=cut

sub getStartTime {
    return $_[0]->{'_start_time'};
}

=pod

=over 4

=item getEndTime ()

This method returns the B<End Time>. The B<End Time> is measured at the moment
when the Sub Process is detected as terminated.

This feature has to be enabled with the C<setProfiling()> method.

It has only a value after the Sub Process is terminated.

B<Returns:> It returns floating point number representing the time when the Sub Process
was terminated and reaped.

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<setProfiling()>|/"setProfiling ( PROFILING )">

=back

=cut

sub getEndTime {
    return $_[0]->{'_end_time'};
}

=pod

=over 4

=item getExecutionTime ()

This method returns the B<Execution Time>. The B<Execution Time> is the micro second
precision time span between the launch of the Sub Process until its termination.

This feature has to be enabled with the C<setProfiling()> method.

It has only a value after the Sub Process is terminated.

B<Returns:> It returns floating point number representing the B<Execution Time>.

See L<Method C<Launch()>|/"Launch ()">

See L<Method C<setProfiling()>|/"setProfiling ( PROFILING )">

=back

=cut

sub getExecutionTime {
    return $_[0]->{'_execution_time'};
}

sub isProfiling {
    return $_[0]->{'_profiling'};
}

sub isDebug {
    return $_[0]->{'_debug'};
}

return 1;
