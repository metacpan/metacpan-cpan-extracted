package Net::Autoconfig;

use 5.008008;
use strict;
use warnings;

use Log::Log4perl qw(:levels :easy);
use Net::Autoconfig::Device;
use Net::Autoconfig::Template;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Cwd;
use version; our $VERSION = version->new("v1.13.2");

################################################################################
# Constants and Global Variables
################################################################################

use constant TRUE	=>	1;
use constant FALSE	=>	0;

use constant MAXIMUM_MAX_CHILDREN => 256; # Absolute Maximum # of child processes (if using bulk mode)
use constant DEFAULT_MAX_CHILDREN => 64;  # Default max # of child processes (if using bulk mode)
use constant MINIMUM_MAX_CHILDREN => 1;   # Absolute Minimum # of child processes (if using bulk mode)

use constant DEFAULT_DIR          => '/usr/local/etc/autoconfig';
use constant DEFAULT_LOGFILE      => DEFAULT_DIR . '/logging.conf';

use constant MAXIMUM_LOG_LEVEL    => 5;   # Absolute Maximum log level
use constant DEFAULT_LOG_LEVEL    => 3;   # Set the default log level to info
use constant MINIMUM_LOG_LEVEL    => 0;   # Absolute Minimum log level

use constant DEFAULT_BULK_MODE    => TRUE; # Enable parallel processing by default

####################
# Friendly User Prompt Messages
####################
use constant USER_PROMPTS => {
    'password'          =>  "Device Access Password",
    'enable_password'   =>  "Device Admin  Password",
    'console_password'  =>  "Console Server Access Password",
};


# A hash ref to store child processes.
# Contains active processes, and return values
our $CHILD_PROCESSES = {};
$CHILD_PROCESSES->{'active'}   = {};
$CHILD_PROCESSES->{'finished'} = {};
$CHILD_PROCESSES->{'info'}     = {};

# Zombies are dead child processes that need to
# be reaped.
our $ZOMBIES;

# Setup signal handling for reaping our own zombies.
# Zombie handling is done by _reaper, which is in the
# private methods section.
$SIG{'CHLD'} = sub { $ZOMBIES++ };

################################################################################
# Methods
################################################################################

############################################################
# Public Methods
############################################################

########################################
# new
# public method
#
# Create a new Net::Autoconfig object.
#
# Log levels (not implemented yet):
# 0 = Fatal => Least verbose
# 1 = Error
# 2 = Warn
# 3 = Info
# 4 = Debug
# 5 = Trace => Most verbose
#
########################################
sub new {
	my $invocant  = shift; # calling class	
	my $class     = ref($invocant) || $invocant;
	my $log       = Log::Log4perl->get_logger($class);
    my %user_data = @_;

	my $self = {
				bulk_mode		=>	DEFAULT_BULK_MODE,
				log_level		=>	DEFAULT_LOG_LEVEL,
				max_children	=>	DEFAULT_MAX_CHILDREN,
                logfile         =>  DEFAULT_LOGFILE,
				};

    $self = bless $self, $class;

    $self->logfile(      $user_data{'logfile'} );
    $self->init_logging();

    $self->bulk_mode(    $user_data{'bulk_mode'} );
    $self->log_level(    $user_data{'log_level'} );
    $self->max_children( $user_data{'max_children'} );

	$log->info("########################################");
	$log->info("#       Net::Autoconfig Started        #");
	$log->info("########################################");
	return $self;
}

########################################
# init_logging
# public method
#
# Initialize logging for Net::Autoconfig.
# If multiple Net::Autoconfig objects
# are created, calling this will affect
# all of them; it changes their logging
# definitions.
#
# Returns undef
########################################
sub init_logging {
    my $self = shift;

    # XXX - Setup a saner, \$log_string
    # config so it's not just to stdout/stderr

    if ( -e $self->logfile )
    {
		eval {
			Log::Log4perl::init( $self->logfile );
		};
		if ($@) {
			print STDERR "Failed to initialize '" . $self->logfile
                          . "' even though it exists.\n";
			print STDERR "Logging to STDERR.";
			Log::Log4perl->easy_init($WARN);
		}
    }
    else
    {
		print STDERR "logging.conf does not exist!";
		print STDERR "Logging to STDERR.";
		Log::Log4perl->easy_init($INFO);
    }
    return;
}

########################################
# bulk_mode
# public method
#
# Accessor/Mutator method
# If passed a parameter, set the
# bulk_mode value to TRUE or FAlSE
#
# If passed undef, return the
# bulk_mode value (TRUE or FALSE);
########################################
sub bulk_mode {
    my $self = shift;
    my $mode = shift;
    my $log  = Log::Log4perl->get_logger( ref($self) );

    if (defined $mode)
    {
        $log->debug("Setting bulk_mode to " . ($mode ? TRUE : FALSE));
        $self->{'bulk_mode'} = $mode ? TRUE : FALSE;
    }
    return defined $mode ? undef : $self->{'bulk_mode'};
}

########################################
# log_level
# public method
#
# Accessor/Mutator method
# If passed a parameter, set the
# log_level to the passed value (or within 0-5)
#
# If passed undef, return the
# log_level value.
########################################
sub log_level {
    my $self  = shift;
    my $level = shift;
    my $log   = Log::Log4perl->get_logger( ref($self) );
    
    if (defined $level)
    {
        $level = int($level);
        if ($level > MAXIMUM_LOG_LEVEL)
        {
            $level = MAXIMUM_LOG_LEVEL;
            $log->warn("Log level set too high.  Setting to " . MAXIMUM_LOG_LEVEL);
        }
        elsif ($level < MINIMUM_LOG_LEVEL)
        {
            $level = MINIMUM_LOG_LEVEL;
            $log->warn("Log level set too low.  Setting to " . MINIMUM_LOG_LEVEL);
        }
        $log->debug("Setting log_level to $level");
        $self->{'log_level'} = $level;
    }
    return defined $level ? undef : $self->{'log_level'};
}

########################################
# max_children
# public method
#
# Accessor/Mutator method
# If passed a parameter, set the
# maximum number of child processes.
# Only used when "bulk_mode" is enabled.
#
# If passed undef, return the
# max number of children.
########################################
sub max_children {
    my $self         = shift;
    my $max_children = shift;
    my $log          = Log::Log4perl->get_logger( ref($self) );

    if (defined $max_children)
    {
        if ($max_children > MAXIMUM_MAX_CHILDREN)
        {
            $max_children = MAXIMUM_MAX_CHILDREN;
            $log->warn("Log max_children set too high.  Setting to '256'.");
        }
        elsif ($max_children < MINIMUM_MAX_CHILDREN)
        {
            $max_children = MINIMUM_MAX_CHILDREN;
            $log->warn("Log max_children set too low.  Setting to '1'.");
        }
        $log->debug("Setting max_children to $max_children");
        $self->{'max_children'} = $max_children;
    }
    return defined $max_children ? undef : $self->{'max_children'};
}

########################################
# get_report
# public method
#
# Return info about the finished processes.
# Returns a hash ref with:
# 'succeded'=> { list of hostnames }
# 'failed'  => {list of hostnames  }
########################################
sub get_report {
    my $self = shift;
    my $report = {};
    my @succeded;     # devices that exited successfully
    my @failed;       # devices that exited unsuccessfully

    foreach my $device_pid (keys %{ $CHILD_PROCESSES->{'info'} })
    {
        if ($CHILD_PROCESSES->{'finished'}->{$device_pid})
        {
            # it failed
            push(@failed, $CHILD_PROCESSES->{'info'}->{$device_pid});
        }
        else
        {
            # it succeded
            push(@succeded, $CHILD_PROCESSES->{'info'}->{$device_pid});
        }
    }
    $report->{'succeded'} = \@succeded;
    $report->{'failed'}   = \@failed;
    return wantarray ? %$report : $report;
}

########################################
# logfile
# public method
#
# Accessor/Mutator
# 
####################
# Mutator
#
# Sets the logfile if it exists
# (assumes current working directory if
# the filename is not specified absolutely.)
#
# Else, it sets the logfile to the default.
#
# Returns:
#   Success =>  undef
#   Failure =>  error message
####################
# Accessor
#
# Returns
#   the logfile's absolute path
########################################
sub logfile {
    my $self          = shift;
    my $logfile       = shift;
    my $return_value;

    if ( defined $logfile )
    {
        # Check for abs path
        if ( $logfile !~ /^\// )
        {
            $logfile = join('/', getcwd(), $logfile);
        }

        if (-e $logfile)
        {
            $self->{'logfile'} = $logfile;
        }
        else
        {
            $self->{'logfile'} = DEFAULT_LOGFILE;
            print STDERR "\n'$logfile' either does not exist or is unreadable\n";
            print STDERR "\nUsing default logfile " . DEFAULT_LOGFILE . "\n";
        }
        undef $return_value;
    }
    else
    {
        $return_value = $self->{'logfile'};
    }
    return $return_value;
}

########################################
# load_devices
# public method
#
# This method looks at a device config
# file and returns
# an array ref of Net::Autoconfig::Device's.
# Devices are returned in the same order as
# in the device file.
#
# Returns:
# array context     =>  an array of Devices
# scalar context    =>  an array ref of Devices
# undef             =>  failure
########################################
sub load_devices {
    my $self = shift;
    my $filename = shift;
    my $log      = Log::Log4perl->get_logger( ref($self) );
    my $devices  = [];    # an array ref of Net::Autoconfig::Devices, key = hostname
    my $file_format;      # indicates if the file is a hash of arrays, or as hash of hashes of arrays
    my $file_hash_depth;  # an integer of the number of levels of hashes in the device file
    my $current_device;   # the name of the current device to add parameters too
    my $line_counter;     # The current line we're on in the device config file (used for logging)
    my $default_device;   # The default device, helps populate new devices
    $filename or $filename = "";

    # Check for abs path
    if ( $filename !~ /\// )
    {
        $filename = join("/", getcwd(), $filename);
    }

    (&_file_not_usable($filename, "device config")) and return;

    eval
    {
        open(DEVICES, $filename) || die print "Could not open '$filename' for reading: $!";
    };
    if ($@)
    {
        $log->warn("Unable to open '$filename': $@");
        return;
    }

    # Create this here in case someone decides not to use the default
    # device.  Re-set the auto-disover bit
    $default_device = Net::Autoconfig::Device->new( 'auto_discover' => FALSE );
    $default_device->hostname('autoconfig-default');

    while (my $line = <DEVICES>)
    {
        chomp $line;
        next if $line =~ /^#/;
        next if $line =~ /^\s*$/;

        $line_counter++;

        if ($line =~ /^:/)
        {
            # some type of host declaration (host or default)
            $line =~ s/^://;
            $line =~ s/:$//;
            $line =~ s/\s*(.*?)\s*/$1/; #remove preceding and trailing whitespace

            if (not $line)
            {
                $log->warn("In device file, undef device '::' line at $line_counter.");
                next;
            }

            if ($line =~ /default/i)
            {
                $current_device = $default_device;
            }
            elsif ($line =~ /^end$/)
            {
                if ($current_device->hostname !~ /autoconfig-default/i)
                {
                    $log->trace("Adding " . $current_device->hostname
                                . " to the list of devices.");
                    $current_device = $current_device->auto_discover;
                    push(@$devices, $current_device);
                }
                undef $current_device;
            }
            else
            {
                $current_device = Net::Autoconfig::Device->new(
                                                $default_device->get(),
                                                'hostname' => $line,
                                                );
            }
        }
        elsif ($line =~ /\s*(.*?)\s*=\s*(.*?)\s*$/)
        {
            my $key = $1;
            my $value = $2;
            if (not $current_device)
            {
                $log->warn("No device is currently configured at line $line_counter.");
                next;
            }
            if ($log->is_trace())
            {
                $log->trace("line # = $line_counter");
                $log->trace("line   = '$line'");
                $log->trace("key    = '$key'");
                $log->trace("value  = '$value'");
            }

            if ($value =~ /\<prompt\>/i)
            {
                my $user_prompts = USER_PROMPTS;
                my $hostname     = $current_device->hostname;
                my $message      = $user_prompts->{$key};
                if (not $message)
                {
                    $message = $key;
                }
                if ($hostname eq $default_device->hostname)
                {
                    $hostname = "Default";
                }
                $message = "[$hostname] - $message";
                $value = &_get_password($message);
            }

            $current_device->set($key => $value);
        }
        else
        {
            $log->warn("Invalid key = value line. Line = '$line'.");
        }
    }

    close(DEVICES);
    return wantarray ? @$devices : $devices;
}

########################################
# load_template
# public method
#
# Load a configuration template from disk.
# These files use the colon file format.
# See documentation for more details.
#
# Returns
#   success =>  a hash ref of the different hosts/devices types
#   failure =>  undef
########################################
sub load_template {
    my $self     = shift;
    my $filename = shift;
    my $log      = Log::Log4perl->get_logger( ref($self) );
    my $template;
    $filename or $filename = "";

    # Check for abs path
    if ( $filename !~ /^\// )
    {
        $filename = join("/", getcwd(), $filename);
    }

    (&_file_not_usable($filename, "template file")) and return;

    $template = Net::Autoconfig::Template->new($filename);

    return $template;
}

########################################
# autoconfig
# public method
#
# Takes a hash ref of device files and
# a template file, and executes the commands on all of the devices.
#
# There are two ways a template can be applied to a device.
# If the device model matches a template entry, then that is
# applied first.  If the device name matches a template entry,
# then that is applied to the device second.
#
# This allows for a device to receive a "generic" configuration
# destined for all devices first, and a more "specific" configuration
# later.
#
# Takes:
#   $devices_hash_ref, Net::Autoconfig::Template
#
# Returns:
#   success = undef
#   failure = An array or array ref (contextual) of the failed devices
########################################
sub autoconfig {
    my $self = shift;
    my $devices = shift;
    my $template = shift;
    my $failed_ping_test;   # results from doing the ping test on the device
    my $log = Log::Log4perl->get_logger( ref($self) );

    if (ref($self) !~ /Net::Autoconfig/)
    {
        $log->warn("Autoconfig not called as a method.");
        return "Autoconfig not called as a method.";
    }

    if (not $devices)
    {
        $log->warn("No devices passed to autoconfig.");
        return "No devices passed to autoconfig.";
    }
    
    if (not ref ($devices) eq "ARRAY")
    {
        $log->warn("Devices were not passed as an array ref.");
        return "Devices were not passed as an array ref.";
    }

    if (not $template)
    {
        $log->warn("No template passed to autoconfig.");
        return "No template passed to autoconfig.";
    }

    foreach my $device ( @$devices )
    {
        my $child_pid;   # PID of the child process (if used)

        if ($log->is_trace)
        {
            $log->trace("Device about to be configured: " . Dumper($device));
        }

        while (keys %{ $CHILD_PROCESSES->{'active'} } > $self->max_children)
        {
            $log->debug("Reached max # of child processes (" . $self->max_children
                            . ") Waiting for some processes to clear up...");
            &_reaper() if $ZOMBIES;
            sleep(1);
        }

        if ($self->bulk_mode)
        {
            $log->trace("Forking process");
            $child_pid = fork();
            #$log->trace("Fork created for Parent $$ - Child $child_pid. Device " . $device->hostname);
            if ($child_pid == -1)
            {
                # Failed to fork!
                $log->warn("Failed to create child process for device " . $device->hostname);
                next;
            }
            elsif ($child_pid)
            {
                # I'm the parent
                $log->debug("Parent $$ - Child $child_pid - Current Device : " . $device->hostname);
                $log->debug("Child $child_pid bulk_mode = " . $self->bulk_mode());
                $CHILD_PROCESSES->{'active'}->{$child_pid} = $device->hostname;
                $CHILD_PROCESSES->{'info'}->{$child_pid}   = $device->hostname;
                next;
            }
            else
            {
                # This is the child
                $log->debug("Child process started for " . $device->hostname);
            }
        }

        if ($device->provision)
        {
            $device->hostname =~ /\A(.*)\@(.*)$/;
            if ($1 and $2)
            {
                # Well formed provisioning hostname
                $failed_ping_test = &_failed_ping_test($2);
            }
            else
            {
                # Poorly formed or normal hostname
                $log->warn("Provisioning hostname " . $device->hostname . " poorly formed.");
                $failed_ping_test = TRUE;
            }
        }
        else
        {
            $failed_ping_test = &_failed_ping_test($device->hostname);
        }

        if ($failed_ping_test)
        {
            my $hostname = $device->hostname || "";
            $log->warn("$hostname was not reachable via ping.  Aborting configuration attempt.");
            if ($self->bulk_mode)
            {
                exit;
            }
            else
            {
                next;
            }
        }

        # Establish a connection to the device first
        $device->provision and $device->console_connect();
        $device->connect();
        $device->get_admin_rights();
        $device->disable_paging();

        $device->provision and $device->lookup_model;

        # Do the generic, device model/type template first
        # device->model returns an array ref, a device can match more
        # than one device type.  Take the first one that exists in the template.
        MODEL_CONFIG:
        foreach my $model ( @{ $device->model } )
        {
            if ($template->{ $model } )
            {
                $log->info("Starting generic, model based using template"
                            . " '$model' to configure " . $device->hostname);
                $device->configure($template->{ $model });
                last MODEL_CONFIG;
            }
            else
            {
                $log->info("No generic, model based template called '$model'" .
                            " for host " . $device->hostname);
                next MODEL_CONFIG;
            }
        }

        if ($template->{$device->hostname})
        {
            # Do the host specific template second.
            $log->info("Starting specific, hostname based configuration");
            $device->configure($template->{ $device->hostname });
        }
        else
        {
            $log->info("No specific, hostnamed based template defined for host " . $device->hostname);
        }
        $device->end_session();

        if ($self->bulk_mode)
        {
            if ($child_pid == 0)
            {
                $log->trace("Terminating child process $$ for host " . $device->hostname);
                exit;
            }
        }
    }

    while (keys %{ $CHILD_PROCESSES->{'active'}})
    {
        $log->debug("Waiting for child processes to terminate. Sleeping for 5 seconds.");
        &_reaper() if $ZOMBIES;
        sleep(5);
    }

    $log->info("Autoconfig Finished.");

    return;
}

############################################################
# Private Methods
############################################################
#
########################################
# _get_password
# private function
#
# Get a password from the user.
# I.e. prevent local echoing of their
# password.
########################################
sub _get_password {
    my $prompt     = shift;
    my $log        = Log::Log4perl->get_logger( __PACKAGE__ );
    my $message    = "";
    my $user_input = "";

    if (not $prompt)
    {
        $log->debug("get_password - Prompt not specified");
        $prompt = "(Not Specified)";
    }

    $message = "[User Input] - $prompt: ";

    $log->trace("get_password - Message = '$message'");
    print $message;

    # Hide user input
    # This only works on linux/unix machines.
    $log->trace("get_password - hiding user text input");
    system("stty -echo");

    $user_input = <STDIN>;
    chomp($user_input);
    $log->trace("get_password - password = '$user_input'");

    # Show user input again.
    $log->trace("get_password - showing user text input");
    system("stty echo");
    print "\n";

    return $user_input;
}


########################################
# _file_not_usable
# private method
#
# Check to see if a file exists, is readable,
# etc.
#
# Takes a filename and a description about the file
# E.g. "device configs" or "firmware tempalte"
#
# Return FALSE if it's okay.
# Return TRUE if it's not
########################################
sub _file_not_usable {
    my $filename     = shift;
    my $file_descrip = shift;
    my $working_dir  = getcwd();
    my $log          = Log::Log4perl->get_logger( __PACKAGE__ );
    $file_descrip = $file_descrip || "";

    if (! $filename)
    {
        $log->warn("$file_descrip: filename not defined.");
        return TRUE;
    }

    if (-d $filename)
    {
        $log->warn("$file_descrip: filename, '$filename' is a directory.");
        return TRUE;
    }

    if (not -e $filename)
    {
        $log->warn("$file_descrip: '$filename', does not exist.");
        return TRUE;
    }

    if (not -r $filename)
    {
        $log->warn("$file_descrip: '$filename', is not readable.  Check file permissions.");
        return TRUE;
    }

    # Ergo, it must be okay!
    return FALSE;
}


sub _failed_ping_test {
    my $hostname = shift;
    return;
}

##############################
# _reaper
# private method
#
# Takes care of waiting for child processes to finish
# so they don't become zombies.  Also does some
# book keeping so we know which processes succeded
# and which ones failed; which ones/how many are active
##############################
sub _reaper {
    my $zombie;
    my $log = Log::Log4perl->get_logger( __PACKAGE__ );

    $log->trace("Start reaping zombies.");
    $log->trace("Number of zombies        : $ZOMBIES");
    $log->trace("Number of active children: " . int(keys %{ $CHILD_PROCESSES->{active} }));

    $ZOMBIES = 0;

    # This is a little tricky.
    # waitpid returns the process id of a zombie that needs to
    # be reaped.  It returns 0 for active procsses.  It returns
    # -1 when there are no child processes left.
    # You'll see code that has <blah> != -1, We want to
    # keep going when child processes are active and
    # only reap the dead processes.
    while (($zombie = waitpid(-1, WNOHANG)) > 0)
    {
        $CHILD_PROCESSES->{'finished'}->{$zombie} = $? >> 8;
        delete $CHILD_PROCESSES->{'active'}->{$zombie};
    }

    $log->trace("Done reaping zombies.");
    return;
}

# Module must return true.
TRUE;

__END__

################################################################################
# Documentation
################################################################################

=head1 NAME

Net::Autoconfig - Perl extension for provisioning or reconfiguring network devices.

=head1 SYNOPSIS

  use Net::Autoconfig;

  $autoconfig  = Net::Autoconfig->new();
  $devices     = load_devices('path/to/device.cfg');
  $template    = load_template('path/to/template.cfg');

  $autoconifg->autoconfig($devices, $template);

=head1 DESCRIPTION

Net::Autoconfig was created to fill the void of having a utility
to configure / provision devices in an automated way.  The reason
for its existence came about from having to deploy 150 new switches
that were almost identically configured, except for the names,
ip addresses and vlans.  The devices had to be unpacked, firmware
upgraded, given an initial configuration, and then given their
final configuration.  This process is error-prone and takes a long
time.  Using this module enabled one person to configure all 150
switches within a week.

This module will also configure switches that are currently
reachable via the network.  This makes it easy to upgrade all
of the firmware or configurations on a large number of devices
without having to do it manually.  It provides the flexibility
to not have to edit / write a script to do this for each separate
device type or configuration revision.  There are other modules
that can do this, but this is vendor agnositc.  I.e. it works on
Cisco and HP devices.  It can be extended to handle other vendors
products relatively easily.

The module uses a new file format.  I call it the colon format.
I made it based on the fact that I didn't want to type very much.
It's designed to be flexible without being overly complicated.
See I<Device Fileformat> and I<Template Fileformat> below for
more information.

The device types are auto discovered (if SNMP is enabled.  It will
try to use the command line if that's available and SNMP is not
enabled.  However, that might not work.)  The other option is to
manually set the vendor and device type in the config file.

=head1 FEATURES

=over

=item 1. Multivendor support

As of right now, it supports both Cisco and HP devices.  It would
be realtively easy to add support for another vendor's products.

=item 2. Variable Interpolation

You can define your own variables in the template files.  As long
as those match a variable in the device file, the variable in
the template will be replaced with the value from the device file.

=item 3. Parallel device configuration

By default, it will configure up to 128 devices at the same time.
This decreases the amount of time taken to configure a lot of
deivces.  This value can be changed.  The absolute maximum number
of simultaneous children is 256.  If this is too few, it's fairly
easy to change the value in the module.

=item 4. Syslog style logging

This script will log to a file or to the screen.  Using a config
file, you can specify the level of logging that you want.  This
allows for more or less verbosity.

=item 5. Console server support

This script will connect to a console server and configure
devices that are attached to its ports.  This is very useful
when doing the intial configuration on devices.

=item 6. Dynamic device/vendor discovery

If given a SNMP community and version, it will attempt to
discover what type of device it is connecting to.  If
applicable, it will use a module that is specific to
those devices.  I.e it will handle that device's
idiosyncrasies.

=back

=head1 EXPORT

This module is object oriented.  It does not export any
functions.

=head1 METHODS

=over

=item new( @options )

Create a new Net::Autoconfig object.  You can pass any parameters
you want, but only the following ones will have an effect.

 bulk_mode
 log_level
 max_children

=item init_logging()

Initialize logging for the module.  Right now, it loads
the default config file.

=item load_devices("filename")

Return an array ref of all of the devices in the
specified file.  The file needs to be in colon format.  You can specify
any key => value pair that you want.  There are some predefined ones,
but you can safely ignore those if you want.

Devices are returned in the same order as they appear in the
device configuration file.

B<Note:> Versions prior to 1.12 returned a hash ref.

See the documenation on B<Net::Autoconfig::Device> for information
regarding the fileformat.

=item load_template("filename")

Open a template file and return a Net::Autoconfig::Template.  This
will be used with the autoconfig function.  The template file is
in colon format.  The configurations are specified via
class, hostname, or vendor type.  Any field that is left blank in
a command will be replaced with what is in the default command.
If the default command is omitted, then the script will use it's
own defaults. 

See the documenation on B<Net::Autoconfig::Template> for information
regarding the fileformat.

Returns a Net::Autoconfig::Template device.

=item autoconfig($devices, $template)

Takes an array ref of devices and a Net::Autoconfig::Template object.  It
will try to configure a general per-class-type set of commands first
and then a set of commands specific to that device.  Any combination
of command sets are permissable.  It will send a notification if
any commands fail for a paticular device.

B<Note:> Prior to version 1.12, $devices was a hash ref

=item bulk_mode(TRUE/FALSE/undef)

Bulk mode is enabled by default.

Will set the bulk mode (aka parallel processing) flag if
passed a TRUE or FALSE value.  It will return the current
bulk_mode status if passed nothing (i.e. undef).

=item max_children($value/undef)

Max_children is 64 by default.

If passed undef, it returns the current maximum number of
simultaneous processes to run if bulk_mode is enabled.
If passed a value, it sets the maximum number of children
to that value.  The absolute maximum number of child processes
is 256.  If that is too few, you can modify that value in the
module.

=item logfile($filename/undef)

Access/Mutator method.

Sets the location of the logfile if passed the filename.

Returns the location of the logfile if passed undef.

=item log_level($level/undef)

*Note: This value currently has no effect on the operation
of this module.

Set the log level using the logging.conf file.

If passed a value, it will set the log level to that value.
 Possible values are:
 0 - Fatal     - Least logging
 1 - Errors
 2 - Warnings
 3 - Info      (this is the default)
 4 - Debug
 5 - Trace     - Most logging

If passed undef, it returns the current log level.

=item get_report()

This has not been implemented yet, but you are free to call
it to see what it does.  :-)

=back

=head1 LOGGING

For the log file format, see B<Log::Log4perl>.  A helpful logfile
should be included with the module installation.  Make sure the
filename is called "logging.conf" and is located in the current
working directory from where the script is executed.

=head1 SEE ALSO

  Look at the YAML documentation on cpan.org for more information
  regarding the configuration files.


=head1 AUTHOR

Kevin Ehlers E<lt>kevin@uoregon.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kevin Ehlers, University of Oregon.
All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 A WORD OF CAUTION

Using this module, it is very easy to cause a complete network outage
very quickly due to a miss-configuration or a typo.  Please be very
careful about what you do, and test on a single device to make sure
it works correctly.  Neither the author nor the University of Oregon
will be held accountable or responsible if this software is used
inappropriately or without careful consideration for what it is
capable of doing.

=head1 DISCLAIMER OF WARRENTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE
LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM
PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR
OR CORRECTION.

=head1 LIMITATION OF LIABILITY

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE
PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY
OF SUCH DAMAGES.

=cut
