package ScriptUtil;

use 5.008008;
use strict;
use warnings;
use Cwd;
use Fcntl qw(:flock);
use Benchmark;
use File::Log;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use Carp qw(carp confess);
use Moose;
use File::Basename;

our $VERSION   = '0.02';

extends 'Moose::Object';

################################################################################
# Object Attributes:
################################################################################
has 'verbose'               => ( isa => 'Bool', is => 'rw', required => 0, default => 0 );
has 'nolog'                 => ( isa => 'Bool', is => 'rw', required => 0, default => 0 );
has 'nolock'                => ( isa => 'Bool', is => 'rw', required => 0, default => 0 );
has '_parent'               => ( isa => 'Str', is => 'rw', required => 0, default => undef );
has '_bench_start'          => ( isa => 'Benchmark', is => 'rw', required => 0 );
has '_bench_end'            => ( isa => 'Benchmark', is => 'rw', required => 0 );
has '_self_fh'              => ( isa => 'Any', is => 'rw', required => 0, default => undef );
has 'log_debug'             => ( isa => 'Int', is => 'ro', required => 0, default => 5 );
has 'log_path'              => ( isa => 'Str', is => 'rw', required => 0, default => '.' );
has 'log_filename'          => ( isa => 'Str', is => 'rw', required => 0, default => undef );
has 'log_mode'              => ( isa => 'Str', is => 'ro', required => 0, default => '>>' );
has 'log_stderrredirect'    => ( isa => 'Bool', is => 'ro', required => 0, default => 0 );
has 'log_storeexptext'      => ( isa => 'Bool', is => 'ro', required => 0, default => 1 );
has 'log_datetimestamp'     => ( isa => 'Bool', is => 'ro', required => 0, default => 1 );
has 'log_logfiledatetime'   => ( isa => 'Bool', is => 'rw', required => 0, default => 1 );
has 'logger'                => ( isa => 'File::Log', is => 'rw', required => 0, default => undef );
has 'log_rotation'          => ( isa => 'Bool', is => 'ro', required => 0, default => 0 );
has 'log_zip_after_days'    => ( isa => 'Num', is => 'ro', required => 0, default => 2 );
has 'log_rm_after_days'     => ( isa => 'Num', is => 'ro', required => 0, default => 31 );
has '_log_pattern'          => ( isa => 'Str', is => 'ro', required => 0, default => '.log' );

################################################################################
# Methods
################################################################################
# Constructor:
################################################################################
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    # Begin benchmark timing:
    $self->_bench_start(new Benchmark);

    # Get the details of the script using this module:
    my ($package, $parent, $line) = caller;
    $self->_parent($parent);
    
    # Lock ourself, so we only run one process at a time:
    unless ($self->nolock) {
        $self->locker();
    }
    
    # Set up logging if required:
    my $logger = undef;
    unless ($self->nolog) {
        
        # If log rotation is on, we must use date/time file names for log files,
        # Otherwise the current log file we are using will never be rotated:
        if (!$self->log_logfiledatetime && $self->log_rotation) {
            if ($self->verbose) {
                carp("NOTICE: Log file date/time file name format will be used because log rotation has been enabled\n");
            }
            $self->log_logfiledatetime(1);
        }
        
        unless (defined($self->log_filename)) {
            my $log_filename = $parent;
            $log_filename =~ s/.pl$//;
            $log_filename .= '.log';
            $self->log_filename($log_filename);
        }
        
        if (defined($self->log_path)) {
           $self->log_filename(File::Spec->catfile($self->log_path, $self->log_filename));
        }
        
        $self->{'logger'} = File::Log->new(
            {
                debug           => $self->log_debug,
                logFileName     => $self->log_filename,
                logFileMode     => $self->log_mode,
                stderrredirect  => $self->log_stderrredirect,
                StoreExpText    => $self->log_storeexptext,
                DateTimeStamp   => $self->log_datetimestamp,
                LogFileDateTime => $self->log_logfiledatetime,
            }
        ) || confess("- Error: can't create log file: [" . $self->log_filename . "]\n- Cause: $!\n");
    }
    
    $self->echo("Starting up script: [" . $self->_parent . "] whirr click");
    
    # Move into the scripts working directory:
    my $dirname = dirname($parent);
    $self->echo("Moving into path:   [" . $dirname . "] (" . getcwd() . ")");
    chdir($dirname);
    
    # Rotate logs if required:
    if ($self->log_rotation) {
        $self->log_rotate();
    }
    
    return $class->meta->new_object(
        __INSTANCE__ => $self,
        @_,
    );
}
################################################################################
# Method to lock the calling script so only one instance can run
################################################################################
sub locker {
    my $self    = shift;
    
    unless ( defined($self->_self_fh) ) {
        open(SELF_FH,">>",$self->_parent)
            || confess("\n- Error: Cannot open [" . $self->_parent . "]\n- Cause: $!\n");
        
        unless ( flock(SELF_FH, LOCK_EX|LOCK_NB) ) {
            confess("\n- Error: [" . $self->_parent . "] is already running\n- Cause: $!\n");
        }
        
        $self->_self_fh(*SELF_FH);
    }
    
    return $self;
}
################################################################################
# Method to unlock the calling script so other instances can run
################################################################################
sub unlocker {
    my $self    = shift;
    
    if ( defined($self->_self_fh) ) {
        close($self->_self_fh);
        $self->_self_fh(undef);
    }
    
    return $self;
}
################################################################################
# Method to print & log message depending on the demands of the script
################################################################################
sub echo {
    my ($self, $message, $debug) = @_;
    
    unless (defined($debug)) {
        $debug = $self->log_debug;
    }
    
    unless ($self->nolog) { 
        $self->logger->msg($debug, "+ " . $message . "\n");
    }
    
    if ($self->verbose && $debug <= $self->log_debug) {
        print "+ " . $message . "\n";
    }
    
    return $self;
}
################################################################################
# Method to clean white space out of strings
################################################################################
sub trim {
    my ($self, $string) = @_;
    # Trim leading & Trailing Spaces:
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    
    # Trim leading & Trailing Tabs:
    $string =~ s/^\t+//;
    $string =~ s/\t+$//;
    
    return $string;
}
################################################################################
# Method to rotate logs
################################################################################
sub log_rotate {
    my $self    = shift;
    
    my $logs_compressed = 0;
    my $logs_deleted    = 0;
    
    $self->echo("Looking for logs to rotate in path: [" . $self->log_path . "]");
    
    opendir(LOG_DIR, $self->log_path)
        || confess("\n- Error, can't open log directory for reading: [" . $self->log_path . "]\n- Cause: $!\n");
    
    while (my $log_file = readdir(LOG_DIR)) {
        
        # Only looking for files that match log pattern:
        my $_log_pattern_match = $self->_log_pattern . "\$";
        my $zip_pattern_match = $self->_log_pattern . ".zip\$";
        next if ($log_file !~ /$_log_pattern_match/i && $log_file !~ /$zip_pattern_match/i);
        
        my $fullpath_log_file;
        if ($self->log_path eq '.') {
            $fullpath_log_file = $log_file;
        } else {
            $fullpath_log_file = File::Spec->catfile($self->log_path, $log_file);
        }

        # And definately skip the current log file we are using:
        if(File::Spec->canonpath($self->logger->getLogFileName()) eq $fullpath_log_file) {
            $self->echo("Skipping current log file (in use): [" . $fullpath_log_file . "]", 10);
        }

        # Get stat info about the log file:
        my @file_info = stat($fullpath_log_file);

        # Current epoch time:
        my $now_epoch = time();
        
        my $log_file_age = (($now_epoch - $file_info[10]) / 86400);

        # If log_zip_after_days is 0 don't do zipping:
        unless ($self->log_zip_after_days == 0) {
            if ($log_file_age >= $self->log_zip_after_days && $log_file !~ /$zip_pattern_match/i) {
                
                $self->echo("Found log file to compress: [" . $fullpath_log_file . "] Age: [" . $log_file_age . "] days old");
                
                my $zip_file = $fullpath_log_file . '.zip';
                $self->echo("Compressing: [" . $fullpath_log_file . "] As: [" . $zip_file . "]");
                
                # Create a zip file object:
                my $zip = Archive::Zip->new();
                
                # Add the log file from disk:
                my $file_member = $zip->addFile($fullpath_log_file);
   
                # Save the zip file:
                unless ($zip->writeToFileNamed($zip_file) == AZ_OK) {
                    confess("\n- Error, can't write zip file: [" . $zip_file . "]\n- Cause: $!\n");
                }
                
                $logs_compressed++;
                
                # Reomove the log file that has been compressed:
                unlink($fullpath_log_file);
                
                $fullpath_log_file = $zip_file;
                
            }
        }

        # If log_rm_after_days is 0 don't do deletions:
        unless ($self->log_rm_after_days == 0) {
            if ($log_file_age >= $self->log_rm_after_days) {
                
                $self->echo("Found log file to remove: [" . $fullpath_log_file . "] Age: [" . $log_file_age . "] days old");
                $self->echo("Deleting: [" . $fullpath_log_file . "]");
                unlink($fullpath_log_file);
                $logs_deleted++;
                
            }
        }
        
    }
    
    $self->echo("Total logs compressed: [" . $logs_compressed . "]");
    $self->echo("Total logs deleted:    [" . $logs_deleted . "]");
    
    return $self;
    
}
################################################################################
# Desstructor:
################################################################################
sub DESTROY {
    my $self    = shift;
    
    $self->unlocker();
    
    # End benchmark timing:
    $self->_bench_end(new Benchmark);
    
    # Calculate execution time:
    my $diff = timediff($self->_bench_end, $self->_bench_start);

    # Benchmark report:
    $self->echo("Benchmark report: " . timestr($diff, 'all'));
    
    $self->echo("Shutting down script: [" . $self->_parent . "] grind clunk");
    
    # Close log file if required:
    unless ($self->nolog) {
        $self->logger->close();
    }
}
################################################################################
1;

__END__

=head1 NAME

ScriptUtil - Object Orientated class to make typical command line scripts easier to write

=head1 SYNOPSIS

 use ScriptUtil;
 # All of these parameters are optional:
 my $script = ScriptUtil->new(
    'verbose'               => 1,            # Output messages to STDOUT
    'nolog'                 => 1,            # Disable logging
    'nolock'                => 1,            # Disable script locking
    'log_debug'             => 5             # Debug level for logging
    'log_filename'          => 'foo.log',    # Log file name
    'log_path'              => '/tmp',       # Location of log files
    'log_mode'              => '>>',         # Log file mode
    'log_stderrredirect'    => 0,            # Redirect stderr into log
    'log_storeexptext'      => 1,            # Log store internally all exp text
    'log_datetimestamp'     => 1,            # Timestamp log data entries
    'log_logfiledatetime'   => 1,            # Timestamp the log file name
    'log_rotation'          => 1,            # Do log rotation if logging is enabled
    'log_zip_after_days'    => 2,            # Zip log files older than X days if log_rotation is enabled
    'log_rm_after_days'     => 5,            # Delete log files older than X days if log_rotation is enabled
 );

 # Put a message into the log file unless the 'nolog' flag has been set
 # Also print to STDOUT if the verbose flag has been set
 
 $script->echo("Boo");
 
 # Put a message into the log file unless the 'nolog' flag has been set
 # And 'log_debug' is greater than or equal to 10
 
 $script->echo("Boo", 10);

=head1 DESCRIPTION

ScriptUtil is a class to make typical command line scripts easier to write.

The aim of this module is to reduce the amount of copy & paste and repeated 'scaffolding code' at the top of your scripts.

As time goes by I intend to add more methods for common operations, if you have some suggestions feel free to drop me a line.


Common operations such as:

=over 4

=item * log file initialization (I<File::Log>)

=item * log file rotation

=item * locking (so only one instance of your scripts runs at a time)

=item * benchmarking performance (I<Benchmark>)

=item * cleaning white space out of strings

=back

Will be taken care of for you when you instantiate a new I<ScriptUtil> object.

You can override some or all of the defaults, or leave them as is, see the examples section for more information

=head1 EXAMPLES

 use ScriptUtil;

 my $script = ScriptUtil->new(
                              verbose       => 1,
                              log_path      => '/var/logs/foo',
                              log_rotation  => 1,
                              log_debug     => 1,
                              );

 $script->echo("Cleaning up a string", 1);
 
 my $string = "\t Foo Bar              \t\t    \n\n\n";
 $script->echo("String Before Cleanup: [" . $string . "]", 10); # log_debug = 1 so you won't see this
 
 $string = $script->trim($string);
 $script->echo("String After Cleanup: [" . $string . "]"); # uses default debug level you will see this
 
 $script->verbose(0);
 $script->echo("You will only see this message in the log file", 1);

=head1 METHODS

There are no class methods, the object methods are described below.
Private methods start with the underscore character '_' and
should be treated as I<Private>.

=head2 new

Called to create a I<ScriptUtil> object.  The following named parameters can be
passed to the constructor in I<Moose> style and they are all B<optional>:

=over 4

=item verbose

Used to determine how noisy the script should be. when C<echo> is called this attribute will
determine if messages should be printed to STDOUT. The default behavior is off (false).

=item nolog

Logging is done via Greg George's handy I<File::Log> object by default.
If you don't want logging set this to false.
The default is on (true) IE logging will be done by default.

=item nolock

Disable script locking, when your script instantiates a I<ScriptUtil> object, I<ScriptUtil> will open
your script in append mode and attempt to get get an exclusive lock.
If it is unable to get a lock, I<ScriptUtil> will C<confess> about it.
The default behavior is off (false) IE scripts will be locked by default.

=item log_debug

Debug level for logging, see I<File::Log> for more information.
Default level is 5.

=item log_filename

Log file name if logging is enabled, see I<File::Log> for more information.
The default value is C<your_script_name.log>.
Or C<your_script_name_YYYYMMDD-HHMMSS.log> if C<log_datetimestamp> is true.

=item log_path

Location of log files if logging is enabled.
The default value is C</path/to/your/script/>.

=item log_mode

Log file mode, see I<File::Log> for more information.
The default value is >> IE append mode.

=item log_stderrredirect

Redirect STDERR into log file, see I<File::Log> for more information.
You should probably leave this off if you are running in verbose mode.
The default behavior is off (false) IE STDERR will not be redirected into logs.

=item log_storeexptext

Log store internally all exp text, see I<File::Log> for more information.
The default value is on (true).

=item log_datetimestamp

Timestamp log data entries, see I<File::Log> for more information.
The default value is on (true).

=item log_logfiledatetime

Timestamp the log file name, see I<File::Log> for more information.
If you are using log rotation this will be set to on automatically.
The default value is on (true).

=item log_rotation

Do log rotation if logging is enabled.
The default value is off (false).

=item log_zip_after_days

Zip log files older than X days if log_rotation is enabled.
The default value is 2 days.

This can be set to C<0> days if you don't want zipping.

=item log_rm_after_days

Delete log files older than X days if log_rotation is enabled.
The default value is 31 days.

This can be set to C<0> days if you don't want deletion.

=back

=head2 echo

Outputs print messages into the log file unless C<nolog> has been set, and to STDOUT if C<verbose> has been set.

Takes a string and an optional integer as arguments.

 # Usage:
 echo(STRING message, INTEGER debug level)

 # Examples:
 $script->echo("This is a message");
 $script->echo("This is a message with a debug level", 10);

=head2 trim

Trims white space (tabs and spaces) out of a string.

Takes a string as an argument, returns a string.

 # Usage:
 STRING = trim(STRING text)

 # Example:
 my $trimmed_string = $script->trim("\t  \t This is a string that needs trimming    ");

=head1 REQUIRED MODULES

=over 4

=item * Moose

=item * Carp

=item * File::Log

=item * Fcntl

=item * Archive::Zip

=item * File::Spec

=item * File::Basename

=back

=head1 VERSION

 0.02
 
=head1 CHANGE LOG

=head2 0.01

Initial release

=head2 0.02

Updated Makfile.PL to correct dependancy problems

=head1 AUTHOR

Cameron Stuart cam@asoftware.net.au

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Cameron Stuart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut